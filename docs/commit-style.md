# Commit style

## Subject

```
<scope>: <imperative summary>
```

- Scope is the thing touched: a package attr (`shipwright:`), a hostname
  (`hee-ho:`), a module area (`minecraft-servers:`, `home:`, `users:`),
  `flake`, `docs`, `treewide` for a sweep across unrelated packages, or a
  comma list with no space for multi-scope changes (`svends,synergyds:`). A
  package scope is the attr as spelled in `pkgs/all-packages.nix`, not
  `meta.pname` — `shipwright_stable:`, not `shipwright-stable:`.
- Multi-scope subjects are a comma-separated list of terms, with brace
  expansion inside a term, so `shipwright{,_stable,-ap},_2ship2harkinian:`
  names four attrs. That is how nixpkgs' build queuer reads the prefix — it
  wraps the whole thing in braces and expands once, so a top-level comma and
  a brace group mean the same thing to it. Collapse a term only where it is
  real expansion, two or more alternatives: `shadps4{,-qtlauncher}:`, not
  `shadps4{-qtlauncher}:`, which is a lone alternative and stays literal.
  Expand each term in bash or zsh before committing; every name it prints
  must be an attr in `pkgs/all-packages.nix`. A brace scope won't match
  `git log --grep=<attr>`; trace a package with `git log -- <path>` instead.
- No conventional-commit type prefixes (`feat(…)`, `fix(…)`, `chore:`).
  Nothing in this repo consumes them, the type taxonomy invites judgment
  calls that decay into `chore(`, and the verb already carries that
  information (`hee-ho: work around the I219-V NIC hang`). A sweep across
  unrelated packages is `treewide:`, not `chore:`.
- Lock updates are `flake: update inputs`; `nix-update` commits keep their
  generated `pkg: old -> new` form.

## Body

No body by default. Most commits, including nontrivial ones, are fully
served by the subject line; writing a body is a conscious exception, not
a habit, and stays to a sentence or two when it happens.

Never include:

- Anything about the system that the repo doesn't already show — the
  message describes the change, not the setup.
- Links or references to upstream projects and issues (URLs, `owner/repo#N`,
  `@mentions`) — those live in source comments only, since rebases and
  force-pushes re-trigger cross-references.
- Narration of the diff, conversation context ("post-review", "as
  discussed"), or references to the author in the third person.

## Trailers

A commit an agent wrote ends with that agent's `Co-authored-by:` trailer,
blank line before it. It is attribution, not a body — it needs no
justification and doesn't make the commit one with a body. It creates no
cross-reference, so unlike an issue link a rebase re-triggers nothing.
Nothing else carries one: not tooling output like `nix-update` bumps, not
commits written by hand.

The Never include rules apply to trailers too. `Fixes: owner/repo#N` is out
for the same reason its prose form is.
