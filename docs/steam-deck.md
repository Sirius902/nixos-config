# Steam Deck

A runbook, not a convention doc: how the Deck's Home Manager generation is
built, pushed and activated, and what to do when something about that breaks.

The Deck runs a single-user, rootless Nix and a standalone Home Manager
generation. Everything is built on the workstation and pushed; nothing is ever
built or evaluated on the Deck, and nothing is installed outside `/nix/store`
and `$HOME`.

The generation owns the whole of `~/.nix-profile`, Nix itself included, so a
deploy updates the Nix binary along with everything else and nothing else may
be installed there by hand.

## Deck prerequisites

- **`/nix` is a bind mount** from `/.steamos/offload/nix`, on the persistent
  partition, which is what makes the store survive a SteamOS update. Check it
  with `findmnt /nix`. If an update leaves it unmounted, remount it
  (`sudo mount --bind /.steamos/offload/nix /nix`) before deploying — Nix will
  otherwise happily start a second store on the rootfs.
- **`experimental-features = nix-command`** in `~/.config/nix/nix.conf`.
  Activation uses `nix profile install` once `~/.nix-profile/manifest.json`
  exists. Do not manage that file from Home Manager: `linkGeneration` and
  `installPackages` are unordered siblings of the activation DAG, so it would
  race.

## First activation

`just deploy-deck` in three steps, because the profile has to be emptied
between the copy and the activation:

```console
$ gen=$(just build-deck)
$ nix copy --no-check-sigs --substitute-on-destination \
    --to "ssh://deck@steamdeck?remote-program=~/.nix-profile/bin/nix-store" "$gen"
$ ssh deck@steamdeck 'nix profile remove --all'
$ ssh deck@steamdeck "HOME_MANAGER_BACKUP_EXT=hm-bak exec '$gen/activate'"
```

`nix profile install` fails on a file already claimed by another element, and
the generation ships every one of those names, so `~/.nix-profile` has to be
empty of anything Home Manager does not own. It cannot be emptied earlier: the
copy resolves `remote-program` through that same profile. Between the two, the
Deck has no `nix` on `PATH` — recover with the store path
`nix profile list` printed, or with `$gen/activate`, which carries its own.

`HOME_MANAGER_BACKUP_EXT` is the standalone equivalent of
`home-manager.backupFileExtension`, which does not exist outside the NixOS
module. It is needed on the first run only: any `.otr`, `.nrm` or `.so` sitting
in a mod directory as a real file makes `checkLinkTargets` abort.

Also clear what the old pipeline left behind:

- Repoint every Steam shortcut (below) and drop the `runNixApp.sh` wrapper and
  any `--strip` argument.
- `nix-env -p ~/.local/state/nix/profiles/games --delete-generations old`, then
  `rm ~/.local/state/nix/profiles/games*` and `nix-collect-garbage`.

## Steady state

```console
$ just deploy-deck
```

`DECK_HOST` overrides the default hostname. `--substitute-on-destination` has
the Deck pull unpatched paths — Mesa above all — from cache.nixos.org rather
than over wifi; the personal-fork paths still come from the workstation.
Substitution is not a build.

Activation is a DAG, not a transaction: `checkLinkTargets` →
`writeBoundary` → `installPackages` + `linkGeneration`. The usual failure, a
real file where a link belongs, aborts in `checkLinkTargets` before anything is
written, and the script is idempotent, so a partial run is fixed by rerunning
it.

## Steam shortcuts

Target `/home/deck/.nix-profile/bin/<exe>`, with no arguments and no wrapper
script. The path never changes across deploys.

| Game | `<exe>` |
| --- | --- |
| Ship of Harkinian | `soh` |
| Ship of Harkinian (stable) | `soh-stable` |
| Ship of Harkinian (Archipelago) | `soh-ap` |
| 2 Ship 2 Harkinian | `2s2h` |
| Dusklight | `dusklight` |
| Dusklight (Archipelago) | `dusklight-ap` |
| Xash3D FWGS | `xash3d` |
| Zelda 64: Recompiled | `Zelda64Recompiled` |

**Set no compatibility tool on these shortcuts.** pressure-vessel builds a
container in which `/nix` does not exist.

`archipelago` and `poptracker` carry the same launcher. They are not games, but
they are SDL and OpenGL, so they need the driver shim below wherever they are
started from — Game Mode shortcut or Desktop Mode alike. `croc`, `hx`, `nix`
and `zellij` are terminal tools and are installed bare.

The Steam overlay and F12 screenshots are lost on the OpenGL titles (the three
soh forks, `2s2h`, `xash3d`): `gameoverlayrenderer.so` arrives by `LD_PRELOAD`,
which is the first thing the launcher unsets. On the Vulkan titles the overlay
arrives as an implicit layer instead, which the launcher keeps, so it should
survive; `VK_LOADER_LAYERS_DISABLE=~implicit~` turns it off if it crashes.
Steam Input, the gamescope FPS overlay and save locations are unaffected —
none work by injection.

## Rollback

```console
$ nix-env -p ~/.local/state/nix/profiles/home-manager --list-generations
$ ~/.local/state/nix/profiles/home-manager-<n>-link/activate
```

## Adding a game

Add it to `modules/home/games/base.nix`, add its attr to the `wrapForSteam`
list in `homes/deck/default.nix`, `just deploy-deck`, and create one shortcut.
A game added to the first list and missed in the second still installs and
still runs from a terminal; it fails on its first launch from Game Mode.

`base.nix` is the set both machines get; the Deck imports it alone. Something
the Deck should not carry goes in `games/full.nix` instead, which is what the
workstation profile imports.

## Why the launchers set what they set

`wrapForSteam` in `overlays/default.nix` generates them, for two unrelated
problems:

**Drivers.** A Nix game links the dispatch libraries — libglvnd and
vulkan-loader hold no driver code — and nixpkgs patches them to find the real
driver under `/run/opengl-driver`. SteamOS has no such path, and creating one
needs root and lands in a rootfs `/etc` that an update discards. Vulkan and EGL
locate their drivers through JSON manifests carrying absolute store paths, so
naming one file each is enough; the GLX vendor is a bare soname `dlopen` with
no manifest, which is why `LD_LIBRARY_PATH` survives, holding exactly
`${mesa}/lib`. Without that, the failure is silent rather than "not found":
SteamOS's `ld.so.cache` serves its own `libGLX_mesa.so.0` into a Nix process.
Which is why the check for it is where the library resolved from, not whether
the game started:

```console
$ LD_DEBUG=libs ~/.nix-profile/bin/soh 2>&1 | grep libGLX_mesa   # /nix/store/…-mesa-…/lib, never /usr/lib
$ VK_LOADER_DEBUG=all ~/.nix-profile/bin/Zelda64Recompiled 2>&1 | grep -i icd   # exactly one, radeon
```

**Injection.** Steam hands a launched process its runtime's `LD_PRELOAD`,
`SDL_DYNAMIC_API`, `GCONV_PATH`, `QT_PLUGIN_PATH` and the rest, every one of
them naming a foreign closure. Those are unset. The list is a blocklist rather
than an `env -i` allowlist: the harmful set is small and stable, the keep-set
is large, session-dependent and grows with every gamescope release, and an
allowlist's failure mode is a black window with no diagnostic.

This is what retires nixGL and its `--strip` argument. nixGL supplied the GLX
vendor by putting its own nixpkgs pin's entire driver closure on
`LD_LIBRARY_PATH`, ahead of every binary's `DT_RUNPATH` — which is where the
`GLIBCXX_3.4.NN not found` class came from. A single directory from the same
pin as the games cannot shadow anything they ship.

`targets.genericLinux.gpu` is mechanically better than this: it creates
`/run/opengl-driver`, so every API resolves with no environment variables at
all, and it covers every Nix app rather than a wrap list. It is rejected only
because `non-nixos-gpu-setup` installs a `tmpfiles.d` rule into `/etc` as root
— a privileged step to redo after every SteamOS update. It would also still
need `wrapForSteam` for the injection half. If the Deck ever becomes a general
Nix desktop rather than a fixed set of games, it becomes the right answer.

If a SteamOS update ever breaks the driver shim outright, the update-proof
answer is to stop using host drivers and ship the graphics stack whole; the
marginal closure for that is about +852 MB.
