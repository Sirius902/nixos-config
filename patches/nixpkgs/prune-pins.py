#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 gitMinimal nix
"""Delete all but the newest retention tags on the nixpkgs fork."""

import argparse
import json
import os
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Final


def run(
    *args: str,
    capture: bool = False,
) -> subprocess.CompletedProcess[str]:
    sys.stdout.flush()
    return subprocess.run(
        args,
        check=True,
        text=True,
        stdout=subprocess.PIPE if capture else None,
    )


REPO: Final = Path(
    run("git", "rev-parse", "--show-toplevel", capture=True).stdout.strip()
)
SPEC_FILE: Final = REPO / "patches/nixpkgs/default.nix"

KEEP: Final = int(os.environ.get("NIXOS_CONFIG_PIN_KEEP") or 30)


def read_spec() -> dict[str, Any]:
    nix = ("nix", "--extra-experimental-features", "nix-command")
    out = run(*nix, "eval", "--file", str(SPEC_FILE), "--json", capture=True)
    spec: dict[str, Any] = json.loads(out.stdout)
    return spec


def prune(dry_run: bool) -> None:
    if KEEP < 1:
        sys.exit("error: NIXOS_CONFIG_PIN_KEEP must be positive")

    spec = read_spec()
    fork, branch = spec["fork"], spec["branch"]
    pattern = f"refs/tags/{branch}/pin-*"

    with tempfile.TemporaryDirectory() as tmp:
        git = ("git", "-C", tmp)
        run("git", "init", "--quiet", "--bare", tmp)
        run(*git, "fetch", "--quiet", "--depth=1", f"https://github.com/{fork}.git",
            f"+{pattern}:{pattern}")

        refs = run(*git, "for-each-ref", "--sort=-creatordate", "--format=%(refname)",
                   pattern, capture=True).stdout.split()
        stale = refs[KEEP:]
        if not stale:
            print(f"{fork} has at most {KEEP} pin tags; nothing to prune.")
            return

        for ref in stale:
            print(f"stale: {ref}")
        if dry_run:
            print("--dry-run: nothing deleted.")
            return

        run(*git, "push", "--atomic", f"git@github.com:{fork}.git",
            *(f":{ref}" for ref in stale))
        print(f"Deleted {len(stale)} pin tags from {fork}.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run", action="store_true", help="only list the stale tags"
    )
    try:
        prune(**vars(parser.parse_args()))
    except subprocess.CalledProcessError as error:
        sys.exit(f"error: {shlex.join(error.cmd)} exited {error.returncode}")


if __name__ == "__main__":
    main()
