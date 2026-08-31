# Patches

How this repo fetches and carries patches. `checks.patch-urls` in `flake.nix`
enforces rules 1, 2, 3, and 5; the rest are conventions to follow by hand.

The rules below govern `fetchpatch` entries and the vendored patches beside
them. nixpkgs itself is patched by a different mechanism — see
[The nixpkgs patch set](#the-nixpkgs-patch-set), which says which of these
rules carry over.

## Template

```nix
# <Imperative one-liner> https://github.com/NixOS/nixpkgs/pull/<N>
(pkgs.fetchpatch {
  name = "<kebab-case-name>.patch";
  url = "https://github.com/<upstream-owner>/<repo>/commit/<sha40>.diff";
  hash = "sha256-…";
})
```

## Rules

1. **Fetcher: `pkgs.fetchpatch` (v1). Never `fetchpatch2`.**

   The two are the same expression instantiated with different patchutils.
   patchutils 0.3.3, pinned permanently for v1, predates git extended headers
   and drops `index` lines; 0.4.2, used by v2, keeps them. GitHub abbreviates
   those blob hashes to a width derived from the fork network's packed object
   count, so it drifts in both directions over time and takes the recorded
   hash with it. `pkgs/README.md` says the same: *"If the patch file contains
   short commit hashes, use `fetchpatch` instead of `fetchpatch2`."*

2. **Extension: always `.diff`. Never `.patch`.**

   A multi-commit `.patch` that creates a file and later modifies it does not
   apply. `fetchpatch`'s `postFetch` regroups hunks by filename with `lsdiff |
   sort -u | xargs filterdiff --include=`; `lsdiff` names a creation
   `b/created.txt` and a later modification `a/created.txt`, `a/` sorts first,
   so `patch -p1` hits the modification before the file exists and aborts. The
   net `.diff` of the same range lists the file once, as a creation, and
   applies cleanly. `.diff` is also far tighter for ranges — the 23-commit niri
   range is 1 entry and 22 hunks as a `.diff` versus 22 entries and 82 hunks as
   a `.patch`. For a single commit the two normalize to byte-identical output,
   so `.diff` is never worse.

   Corollary: for ranges use three-dot `<base>...<head>`, with `<base>` the
   parent of the first commit so the merge base and the literal parent coincide.

3. **No query parameters at all.**

   In particular no `?full_index=1`: it is inert under `fetchpatch`, which
   strips `index` lines regardless, and GitHub ignores it outright on
   `/compare/`. A parameter that does nothing is a false signal.

4. **URLs pin immutable 40-character SHAs**, in one of exactly two forms:

   - single commit: `https://github.com/<owner>/<repo>/commit/<sha40>.diff`
   - range: `https://github.com/<owner>/<repo>/compare/<base-sha40>...<head-sha40>.diff`

5. **Never `https://github.com/<owner>/<repo>/pull/<N>.diff`.**

   A PR URL follows the branch, so a rebase or force-push silently changes the
   content. Resolve the PR to its commit SHAs.

6. **Address the upstream root repository, not a fork.**

   GitHub serves a fork network from a shared object store, so a fork's commits
   are reachable through the root repo and stay reachable if the fork is deleted
   or renamed. Put the fork or PR link in the comment, not the URL.

7. **`name` is always set, kebab-case, and always ends in `.patch`** —
   regardless of the `.diff` URL.

   The `name` describes the artifact, the URL describes where it came from.
   This keeps naming uniform with the vendored patches under `patches/`, which
   are `.patch` files on disk. `name` sets the store path, not the hash.

8. **Every entry carries a comment above it:**
   `# <Imperative one-liner> <upstream PR/issue URL>`, or
   `# TODO(Sirius902) <why>` when no upstream PR exists yet.

9. **Vendor into `patches/<pkg>/<name>.patch` instead of fetching** when the
   patch contains a file rename, a mode change, or a binary hunk, or when it is
   hand-edited or has no immutable forge URL.

   `fetchpatch` silently discards all three of those. A patch that is *entirely*
   a rename fails loudly, but a *mixed* patch loses the rename quietly.

10. **Remove a patch once it lands in `nixos-unstable`**, in a
    `<scope>: drop nixpkgs patch` commit.

## The nixpkgs patch set

nixpkgs itself is not patched with `fetchpatch`. `patches/nixpkgs/default.nix`
declares a patch set, `patches/nixpkgs/update.py` replays it onto the tip of
`nixos-unstable` and pushes the result to the `nixos-config` branch of
`Sirius902/nixpkgs`, and `flake.nix` locks that branch as the `nixpkgs` input.

It is an input so patches to modules, `lib`, and nixpkgs' flake are visible
during evaluation. Fixed entries follow rule 4, every entry follows rule 8,
and the updater enforces rule 10. Fork sources are allowed, and cherry-picked
commits may contain changes that `fetchpatch` cannot carry. Hand-edited patches
still belong in a `file` entry.

`default.nix` is the hand-written specification. `pins.json` records the
channel commit and the immutable base and head resolved for each tracked entry.
It is written only after a successful push.

### Entry kinds

Every entry takes an optional `from = "<owner>/<repo>"`, defaulting to the
channel's repository, and they are replayed in list order.

| Entry                                            | Replayed as                                      |
| ------------------------------------------------ | ------------------------------------------------ |
| `commit = "<sha40>";`                            | that commit                                      |
| `range = {base = "<sha40>"; head = "<sha40>";};` | non-merge commits in `base..head`                |
| `pr = <N>;`                                      | commits in the PR's current base-to-head span    |
| `branch = "<name>"; against = "<ref>";`          | commits since its merge base with `<ref>`        |
| `file = ./<name>.patch;`                         | `git am --3way <file>`                           |

PR bases come from GitHub's simulated merge ref. Its second parent must match
the PR head; its first parent is the base. A recorded base is reused only when
the recorded head is unchanged. Branches require an explicit comparison ref
because a branch alone does not identify its intended base.

Tracked spans follow rebases and force-pushes. `commit` and `range` are fixed
pins. All ranges are replayed in reverse topological order without merge
commits.

### When a source vanishes

If a tracked ref disappears, its recorded span is reused. Commits are fetched
from the named source, then the upstream repository as a fallback. A commit
neither serves must be vendored as a `file` entry.

### Running it

`just update-nixpkgs`, or `just update`, which runs it before
`nix flake update --refresh`. `--refresh` is required there: the branch moved a
line earlier, and Nix caches github ref-to-rev resolution for `tarball-ttl`.

Objects are kept in `~/.cache/nixos-config/nixpkgs`, overridable with
`NIXOS_CONFIG_NIXPKGS_CACHE`. The cache repository itself is not reset or
cleaned. Each replay uses a detached temporary worktree, removes it on success,
and preserves it with a cleanup command on failure.

`SKIP_NIXPKGS=1` makes the script a no-op, for a `just update` that should
leave the branch alone.

The updater compares tree object IDs before pushing because replay timestamps
can change commit IDs without changing content.

### Retention

Every push also creates `refs/tags/<branch>/pin-<sha40>` so older `flake.lock`
revisions remain fetchable after the branch is force-pushed.

`just prune-nixpkgs-pins` deletes all but the newest `NIXOS_CONFIG_PIN_KEEP`
(default 30) of them; `just prune-nixpkgs-pins --dry-run` only lists. It works
in a throwaway repository containing nothing but those tags, so it cannot reach
the branch or any other tag.

The retention tag is the guarantee that the exact commit remains available.
The recorded base and head can reconstruct its tree only while the source
commits remain fetchable.
