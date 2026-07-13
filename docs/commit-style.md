# Commit style

## Subject

```
<scope>: <imperative summary>
```

- Scope is the thing touched: a package attr (`shipwright:`), a hostname
  (`hee-ho:`), a module area (`minecraft-servers:`, `home:`, `users:`),
  `flake`, `docs`, or a comma list for multi-scope changes
  (`svends,synergyds:`).
- No conventional-commit type prefixes (`feat(…)`, `fix(…)`, `chore:`).
  Nothing in this repo consumes them, the type taxonomy invites judgment
  calls that decay into `chore(`, and the verb already carries that
  information (`hee-ho: work around the I219-V NIC hang`).
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
