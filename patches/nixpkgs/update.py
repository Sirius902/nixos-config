#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 gitMinimal nix
"""Replay the nixpkgs patch set and update its fork branch."""

import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Final


class Die(Exception):
    pass


def run(
    *args: str,
    capture: bool = False,
    check: bool = True,
    quiet: bool = False,
    stdin: str | None = None,
) -> subprocess.CompletedProcess[str]:
    sys.stdout.flush()
    return subprocess.run(
        args,
        check=check,
        text=True,
        input=stdin,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.DEVNULL if quiet else None,
    )


REPO: Final = Path(
    run("git", "rev-parse", "--show-toplevel", capture=True).stdout.strip()
)
SPEC_FILE: Final = REPO / "patches/nixpkgs/default.nix"
PINS_FILE: Final = REPO / "patches/nixpkgs/pins.json"
CACHE: Final = Path(
    os.environ.get("NIXOS_CONFIG_NIXPKGS_CACHE")
    or Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
    / "nixos-config/nixpkgs"
)

SHA40: Final = re.compile("[0-9a-f]{40}")


def git(repo: Path, *args: str, **kwargs: Any) -> subprocess.CompletedProcess[str]:
    return run("git", "-C", str(repo), *args, **kwargs)


def has_commit(repo: Path, rev: str) -> bool:
    return (
        git(
            repo,
            "--no-lazy-fetch",
            "cat-file",
            "-e",
            f"{rev}^{{commit}}",
            check=False,
            quiet=True,
        ).returncode
        == 0
    )


def url(repo: str) -> str:
    return f"https://github.com/{repo}.git"


def qualify_branch(ref: str) -> str:
    return ref if ref.startswith("refs/") else f"refs/heads/{ref}"


@dataclass(frozen=True)
class Commit:
    source: str
    rev: str

    @property
    def label(self) -> str:
        return f"commit {self.rev} from {self.source}"


@dataclass(frozen=True)
class Range:
    source: str
    base: str
    head: str

    @property
    def label(self) -> str:
        return f"range {self.base}..{self.head} from {self.source}"


@dataclass(frozen=True)
class PullRequest:
    source: str
    number: int

    @property
    def key(self) -> str:
        return f"{self.source}:refs/pull/{self.number}/head"

    @property
    def label(self) -> str:
        return f"PR {self.source}#{self.number}"


@dataclass(frozen=True)
class Branch:
    source: str
    ref: str
    against: str

    @property
    def key(self) -> str:
        return f"{self.source}:{self.ref}"

    @property
    def label(self) -> str:
        return f"branch {self.ref.removeprefix('refs/heads/')} from {self.source}"


@dataclass(frozen=True)
class PatchFile:
    path: Path

    @property
    def name(self) -> str:
        return str(
            self.path.relative_to(REPO)
            if self.path.is_relative_to(REPO)
            else self.path
        )

    @property
    def label(self) -> str:
        return f"file {self.name}"


Entry = Commit | Range | PullRequest | Branch | PatchFile
ReplayEntry = Commit | Range | PatchFile


@dataclass(frozen=True)
class Spec:
    upstream: str
    channel: str
    fork: str
    branch: str
    entries: tuple[Entry, ...]


def read_spec() -> dict[str, Any]:
    nix = ("nix", "--extra-experimental-features", "nix-command")
    out = run(*nix, "eval", "--file", str(SPEC_FILE), "--json", capture=True)
    spec: dict[str, Any] = json.loads(out.stdout)
    return spec


def parse_spec() -> Spec:
    raw = read_spec()
    upstream = f"{raw['base']['owner']}/{raw['base']['repo']}"

    entries: list[Entry] = []
    for patch in raw["patches"]:
        kinds = {"commit", "range", "pr", "branch", "file"} & patch.keys()
        if len(kinds) != 1:
            raise Die("each patch entry must have exactly one entry kind")

        source = patch.get("from", upstream)
        kind = kinds.pop()
        if kind == "commit":
            entries.append(Commit(source, patch["commit"]))
        elif kind == "range":
            span = patch["range"]
            entries.append(Range(source, span["base"], span["head"]))
        elif kind == "pr":
            entries.append(PullRequest(source, patch["pr"]))
        elif kind == "branch":
            if "against" not in patch:
                raise Die(f"branch {patch['branch']} has no comparison ref")
            entries.append(
                Branch(
                    source,
                    qualify_branch(patch["branch"]),
                    qualify_branch(patch["against"]),
                )
            )
        else:
            entries.append(PatchFile(Path(patch["file"])))

    if not entries:
        raise Die(f"{SPEC_FILE} lists no patches")

    return Spec(
        upstream=upstream,
        channel=qualify_branch(raw["base"]["ref"]),
        fork=raw["fork"],
        branch=raw["branch"],
        entries=tuple(entries),
    )


def read_pins() -> dict[str, Any]:
    if not PINS_FILE.exists():
        return {}
    pins: dict[str, Any] = json.loads(PINS_FILE.read_text())
    return pins


def recorded_span(pins: dict[str, Any], key: str, source: str) -> Range | None:
    raw = pins.get("spans", {}).get(key)
    if raw is None:
        return None
    return Range(source, raw["base"], raw["head"])


def ls_remote(source: str, ref: str) -> str | None:
    listing = run(
        "git",
        "ls-remote",
        url(source),
        ref,
        capture=True,
        check=False,
        quiet=True,
    ).stdout
    return listing.split()[0] if listing else None


def fetch_rev(spec: Spec, repo: Path, source: str, rev: str) -> None:
    if not SHA40.fullmatch(rev):
        raise Die(f"{source}: {rev} is not a full 40-character SHA")
    if has_commit(repo, rev):
        return
    for candidate in dict.fromkeys((source, spec.upstream)):
        fetch = git(
            repo,
            "fetch",
            "--quiet",
            "--filter=tree:0",
            "--no-auto-maintenance",
            "--no-tags",
            "--no-write-fetch-head",
            url(candidate),
            rev,
            check=False,
            quiet=True,
        )
        if fetch.returncode == 0 and has_commit(repo, rev):
            return
    raise Die(
        f"neither {source} nor {spec.upstream} can serve {rev}; "
        "vendor it as a file entry"
    )


def fetch_ref(repo: Path, source: str, ref: str, rev: str) -> None:
    if has_commit(repo, rev):
        return
    fetched = git(
        repo,
        "fetch",
        "--quiet",
        "--filter=tree:0",
        "--no-auto-maintenance",
        "--no-tags",
        "--no-write-fetch-head",
        url(source),
        ref,
        check=False,
        quiet=True,
    )
    if fetched.returncode != 0:
        raise Die(f"could not fetch {source} {ref}")
    if not has_commit(repo, rev):
        raise Die(f"{source} {ref} changed while it was being resolved; retry")


def resolve_pr(spec: Spec, entry: PullRequest, pins: dict[str, Any]) -> Range:
    head_ref = f"refs/pull/{entry.number}/head"
    merge_ref = f"refs/pull/{entry.number}/merge"
    head = ls_remote(entry.source, head_ref)
    if head is None:
        recorded = recorded_span(pins, entry.key, entry.source)
        if recorded is None:
            raise Die(f"{entry.label} is gone and has no recorded span")
        print(f"  {entry.label} is gone; using its recorded span", file=sys.stderr)
        return recorded

    merge = ls_remote(entry.source, merge_ref)
    if merge is None:
        recorded = recorded_span(pins, entry.key, entry.source)
        if recorded is not None and recorded.head == head:
            print(
                f"  {entry.label} has no merge ref; using its recorded base",
                file=sys.stderr,
            )
            return recorded
        raise Die(f"{entry.label} has no merge ref; its base cannot be determined")

    fetch_ref(CACHE, entry.source, head_ref, head)
    fetch_ref(CACHE, entry.source, merge_ref, merge)
    parents = git(
        CACHE, "rev-list", "--parents", "-n1", merge, capture=True
    ).stdout.split()
    if len(parents) != 3 or parents[2] != head:
        raise Die(f"{entry.label} merge ref does not match its head")
    return Range(entry.source, parents[1], head)


def resolve_branch(spec: Spec, entry: Branch, pins: dict[str, Any]) -> Range:
    head = ls_remote(entry.source, entry.ref)
    if head is None:
        recorded = recorded_span(pins, entry.key, entry.source)
        if recorded is None:
            raise Die(f"{entry.label} is gone and has no recorded span")
        print(f"  {entry.label} is gone; using its recorded span", file=sys.stderr)
        return recorded

    against = ls_remote(spec.upstream, entry.against)
    if against is None:
        raise Die(f"{spec.upstream} has no {entry.against}")
    fetch_ref(CACHE, entry.source, entry.ref, head)
    fetch_ref(CACHE, spec.upstream, entry.against, against)
    base = git(CACHE, "merge-base", against, head, capture=True).stdout.strip()
    return Range(entry.source, base, head)


def resolve_entries(
    spec: Spec, pins: dict[str, Any]
) -> tuple[tuple[ReplayEntry, ...], dict[str, Range]]:
    entries: list[ReplayEntry] = []
    spans: dict[str, Range] = {}
    for entry in spec.entries:
        if isinstance(entry, PullRequest):
            span = resolve_pr(spec, entry, pins)
            entries.append(span)
            spans[entry.key] = span
        elif isinstance(entry, Branch):
            span = resolve_branch(spec, entry, pins)
            entries.append(span)
            spans[entry.key] = span
        else:
            entries.append(entry)
    return tuple(entries), spans


def landed(repo: Path, patch: str) -> bool:
    reverse = git(
        repo,
        "apply",
        "--reverse",
        "--check",
        "-",
        stdin=patch,
        check=False,
        quiet=True,
    )
    return reverse.returncode == 0


def paused(worktree: Path, what: str) -> Die:
    return Die(
        f"{what} did not apply; the replay is preserved in {worktree}\n"
        f"inspect it there, then remove it with:\n"
        f"git -C {shlex.quote(str(CACHE))} worktree remove --force "
        f"{shlex.quote(str(worktree))}"
    )


def pick(spec: Spec, repo: Path, source: str, rev: str) -> None:
    patch = git(repo, "diff", f"{rev}^", rev, capture=True).stdout
    if landed(repo, patch):
        raise Die(
            f"{source} {rev} is already in {spec.channel}; drop it from "
            f"{SPEC_FILE} (docs/patches.md rule 10)"
        )
    print(f"  cherry-pick {rev}")
    if git(repo, "cherry-pick", rev, check=False).returncode != 0:
        raise paused(repo, f"{source} {rev}")


def pick_span(spec: Spec, repo: Path, span: Range) -> None:
    listing = git(
        repo,
        "rev-list",
        "--reverse",
        "--topo-order",
        "--no-merges",
        f"{span.base}..{span.head}",
        capture=True,
    )
    revs = listing.stdout.split()
    if not revs:
        raise Die(f"{span.label} adds no commits on top of {spec.channel}")
    for rev in revs:
        pick(spec, repo, span.source, rev)


def apply_file(spec: Spec, repo: Path, patch: PatchFile) -> None:
    if not patch.path.exists():
        raise Die(f"{patch.name} does not exist")
    if landed(repo, patch.path.read_text()):
        raise Die(
            f"{patch.name} is already in {spec.channel}; drop it from "
            f"{SPEC_FILE} (docs/patches.md rule 10)"
        )
    print(f"  am {patch.name}")
    if git(repo, "am", "--3way", str(patch.path), check=False).returncode != 0:
        raise paused(repo, patch.name)


def prepare_cache(spec: Spec) -> None:
    if not CACHE.exists():
        print(f"Cloning {spec.upstream} into {CACHE} (one time, about 1 GB).")
        run(
            "git",
            "clone",
            "--filter=tree:0",
            "--single-branch",
            "--branch",
            spec.channel.removeprefix("refs/heads/"),
            url(spec.upstream),
            str(CACHE),
        )
        return
    if git(
        CACHE,
        "rev-parse",
        "--git-dir",
        capture=True,
        check=False,
        quiet=True,
    ).returncode != 0:
        raise Die(f"{CACHE} exists but is not a Git repository")


def replay(spec: Spec, repo: Path, entries: tuple[ReplayEntry, ...]) -> None:
    for entry in entries:
        print(f"==> {entry.label}")
        if isinstance(entry, Commit):
            fetch_rev(spec, repo, entry.source, entry.rev)
            pick(spec, repo, entry.source, entry.rev)
        elif isinstance(entry, Range):
            fetch_rev(spec, repo, entry.source, entry.base)
            fetch_rev(spec, repo, entry.source, entry.head)
            pick_span(spec, repo, entry)
        else:
            apply_file(spec, repo, entry)


def fetch_tree(source: str, ref: str, rev: str) -> str:
    with tempfile.TemporaryDirectory(prefix="nixos-config-nixpkgs-tree-") as root:
        repo = Path(root)
        run("git", "init", "--bare", "--quiet", str(repo))
        if not has_commit(repo, rev):
            fetched = git(
                repo,
                "fetch",
                "--quiet",
                "--depth=1",
                "--no-auto-maintenance",
                "--no-tags",
                "--no-write-fetch-head",
                url(source),
                ref,
                check=False,
                quiet=True,
            )
            if fetched.returncode != 0:
                raise Die(f"could not fetch {source} {ref}")
        if not has_commit(repo, rev):
            raise Die(f"{source} {ref} changed while it was being resolved; retry")
        return git(repo, "rev-parse", f"{rev}^{{tree}}", capture=True).stdout.strip()


def push(spec: Spec, repo: Path) -> None:
    remote = f"git@github.com:{spec.fork}.git"
    branch = qualify_branch(spec.branch)
    remote_head = ls_remote(spec.fork, branch)
    if remote_head is not None:
        remote_tree = fetch_tree(spec.fork, branch, remote_head)
        local_tree = git(repo, "rev-parse", "HEAD^{tree}", capture=True).stdout.strip()
        if remote_tree == local_tree:
            print(f"{spec.fork} {spec.branch} already holds this tree; nothing to push.")
            return

    pushed = git(repo, "rev-parse", "HEAD", capture=True).stdout.strip()
    pin = f"{spec.branch}/pin-{pushed}"
    print(f"Pushing {pushed} to {spec.fork} {spec.branch} and {pin}.")
    git(
        repo,
        "push",
        "--atomic",
        "--force",
        remote,
        f"HEAD:refs/heads/{spec.branch}",
        f"HEAD:refs/tags/{pin}",
    )


def update() -> None:
    spec = parse_spec()
    prepare_cache(spec)
    pins = read_pins()

    print(f"Fetching {spec.upstream} {spec.channel}.")
    base = ls_remote(spec.upstream, spec.channel)
    if base is None:
        raise Die(f"{spec.upstream} has no {spec.channel}")
    fetch_rev(spec, CACHE, spec.upstream, base)
    entries, spans = resolve_entries(spec, pins)

    worktree_root = Path(tempfile.mkdtemp(prefix="nixos-config-nixpkgs-"))
    worktree = worktree_root / "worktree"
    try:
        git(CACHE, "worktree", "add", "--quiet", "--detach", str(worktree), base)
        replay(spec, worktree, entries)
        push(spec, worktree)
    except BaseException:
        if worktree.exists():
            print(f"replay worktree preserved at {worktree}", file=sys.stderr)
        else:
            worktree_root.rmdir()
        raise
    else:
        git(CACHE, "worktree", "remove", "--force", str(worktree))
        worktree_root.rmdir()

    serialized_spans = {
        key: {"base": span.base, "head": span.head} for key, span in spans.items()
    }
    output = json.dumps(
        {"base": base, "spans": serialized_spans}, indent=2, sort_keys=True
    )
    PINS_FILE.write_text(f"{output}\n")


def main() -> None:
    if os.environ.get("SKIP_NIXPKGS"):
        print("SKIP_NIXPKGS is set; leaving the nixpkgs fork branch alone.")
        return

    try:
        update()
    except Die as error:
        sys.exit(f"error: {error}")
    except subprocess.CalledProcessError as error:
        sys.exit(f"error: {shlex.join(error.cmd)} exited {error.returncode}")


if __name__ == "__main__":
    main()
