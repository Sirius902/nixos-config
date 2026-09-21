# Steam Deck

A runbook, not a convention doc: how the Deck's Home Manager generation is
built, pushed and activated, and what to do when something about that breaks.

The Deck runs a single-user, rootless Nix and a standalone Home Manager
generation. Everything is built on the workstation and pushed; nothing is ever
built or evaluated on the Deck, and nothing outside `/nix/store` and `$HOME` is
touched. The generation owns the whole of `~/.nix-profile`, Nix included, so
nothing may be installed there by hand.

## Deck prerequisites

- `/nix` is a bind mount from `/.steamos/offload/nix`, which is what makes the
  store survive a SteamOS update. `findmnt /nix`.
- `experimental-features = nix-command` in `~/.config/nix/nix.conf`.

## First activation

On a fresh Deck, or after a SteamOS reinstall, the three steps have to be run by
hand, because the profile has to be emptied between the copy and the activation:

```console
$ gen=$(just build-deck)
$ nix copy --no-check-sigs --substitute-on-destination \
    --to "ssh://deck@steamdeck?remote-program=~/.nix-profile/bin/nix-store" "$gen"
$ ssh deck@steamdeck 'nix profile remove --all'
$ ssh deck@steamdeck "HOME_MANAGER_BACKUP_EXT=hm-bak exec '$gen/activate'"
```

The profile cannot be emptied any earlier, because the copy resolves
`remote-program` through it. In between, the Deck has no `nix` on `PATH` —
recover with `$gen/activate`, which carries its own.

`HOME_MANAGER_BACKUP_EXT` is the standalone equivalent of
`home-manager.backupFileExtension`, which exists only in the NixOS module. A
real file where a link belongs otherwise aborts `checkLinkTargets`.

## Steady state

```console
$ just deploy-deck
```

`DECK_HOST` overrides the hostname. `--substitute-on-destination` has the Deck
pull unpatched paths — Mesa above all — from cache.nixos.org rather than over
wifi; substitution is not a build.

## Steam shortcuts

Target `/home/deck/.nix-profile/bin/<exe>`, Start In
`/home/deck/.nix-profile/bin/`, no arguments and no wrapper script. Neither
field may be relative: Steam expands no `~` and resolves `./` against a
directory of its own choosing, and either one fails the `execve` before the
launcher runs, which Game Mode shows as the Play button flicking straight back
from Stop. The paths never change across deploys, and `ls ~/.nix-profile/bin` is
the list of them.

**Set no compatibility tool on these shortcuts.** pressure-vessel builds a
container in which `/nix` does not exist.

The Steam overlay and F12 screenshots are lost on the OpenGL titles:
`gameoverlayrenderer.so` arrives by `LD_PRELOAD`, which the launcher unsets.

An app that seeds `$HOME` from its own installation copies out of the read-only
store; `chmod -R u+w` the directory when that leaves it unwritable.

## Rollback

```console
$ nix-env -p ~/.local/state/nix/profiles/home-manager --list-generations
$ ~/.local/state/nix/profiles/home-manager-<n>-link/activate
```

## Adding a game

Add it to `modules/home/games/base.nix` and `just deploy-deck`, then create one
shortcut. A game that needs mod files linked gets its own module there instead.
Something the Deck should not carry goes in `games/full.nix`, which only the
workstation imports.

## Troubleshooting the launchers

`wrapForSteam` in `overlays/default.nix` generates them, and its comments carry
why each variable is set or unset. Check where a library resolved from rather
than whether the game started — the neighbouring APIs fail soft, and a wrong
`${mesa}` would too:

```console
$ LD_DEBUG=libs ~/.nix-profile/bin/soh 2>&1 | grep libGLX_mesa   # /nix/store/…-mesa-…/lib, never /usr/lib
$ VK_LOADER_DEBUG=all ~/.nix-profile/bin/Zelda64Recompiled 2>&1 | grep -i icd   # exactly one, radeon
```
