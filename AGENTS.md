# AGENTS.md

Conventions for this repo live in `docs/`. Read the relevant one before
changing anything it covers.

- `docs/commit-style.md` — commit subject scope and summary; when a body is
  warranted, what never belongs in one, and the agent trailer.
- `docs/comments.md` — when a comment earns its place in an expression, and
  where a change's reasoning belongs when it doesn't.
- `docs/package-layout.md` — how to lay out `$out` in `pkgs/` derivations so
  packages coexist in a profile without colliding.
- `docs/desktop-entries.md` — `makeDesktopItem` field usage per the
  freedesktop `.desktop` spec.
- `docs/patches.md` — how patches are fetched and carried, and which of those
  rules `checks.patch-urls` enforces.
