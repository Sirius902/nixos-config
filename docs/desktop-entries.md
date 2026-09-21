# Desktop entries

How to use `makeDesktopItem` fields correctly per the freedesktop `.desktop`
spec.

Two spellings reach the same file. A package's own entry uses `makeDesktopItem`,
where the display name is `desktopName`; a home-manager entry uses
`xdg.desktopEntries` (`modules/home/mime.nix`), where that field is `name`.
Everything below applies to both.

## `desktopName` / `name` (maps to `Name=`)

The human-readable display name shown in launchers and menus. Use the full
product name, with a parenthesised variant suffix for alternate builds:

```nix
desktopName = "Ship of Harkinian";           # base
desktopName = "Ship of Harkinian (Stable)";  # variant
```

## `genericName` (maps to `GenericName=`)

A category descriptor, not the product name. Only set it when the value
describes what *kind* of application it is:

- Good: `"Multi-Game Randomizer"` (`archipelago`), `"Text Editor"` and
  `"Terminal"` (`modules/home/mime.nix`)
- Bad: `"Ship of Harkinian"`, `"2 Ship 2 Harkinian"`

Omit it rather than misuse it — most game packages have no meaningful
generic name.
