# Patches

How this repo fetches and carries patches. `checks.patch-urls` in `flake.nix`
enforces rules 1, 2, 3, and 5; the rest are conventions to follow by hand.

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
