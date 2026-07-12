# Package output layout

How to lay out `$out` in derivations under `pkgs/` so packages can coexist in
a profile.

## Why this matters

Profiles (home-manager's `buildEnv`, `nix profile`, `environment.systemPackages`)
merge every installed package's whole `$out` into one symlink tree. Two packages
shipping the same relative path is a conflict: home-manager fails the build,
while the NixOS system profile sets `ignoreCollisions = true` and silently
shadows one of the files.

A derivation with loose files in `bin/` or `lib/` works fine on its own; the
flaw only surfaces when a second package ships the same names. This is exactly
what broke when the games moved into `home.packages`: `dusklight` and
`dusklight-rando` both shipped `bin/res/`, and the soh forks all shipped the
same flat `lib/` app dump.

## Rules

The top level of `$out` is shared namespace. Nothing goes there except the
standard prefixes, and nothing loose goes inside them:

- `bin/` — executables only, uniquely named. Symlinks or wrapper scripts into
  the package's private directory are fine.
- `lib/` — top level is only for libraries other packages link against.
  Anything app-private — dlopen'd plugin modules, mod `.so` trees, bundled
  runtimes — goes in `lib/${pname}/`.
- `share/${pname}/` — the package's private data and self-contained app dirs
  (see below). The merge-designed freedesktop trees keep their usual layout:
  `share/applications`, `share/icons/hicolor`, `share/man`,
  `share/licenses/${pname}`, `share/pixmaps`.
- Never invent top-level directories (`$out/valve`, `$out/2s2h`).

Vendored build detritus (dependency headers, static libs — e.g. StormLib's
`include/` + `lib/` leaking from a cmake install) is deleted in `postInstall`,
not relocated.

## Deciding where a file goes

| What                                                    | Where                                         |
| ------------------------------------------------------- | --------------------------------------------- |
| executable users run                                     | `bin/` (symlink into the app dir is fine)     |
| self-contained app dir (binary + assets kept adjacent)   | `share/${pname}/`, binary symlinked to `bin/` |
| arch-dependent private modules (dlopen'd `.so`, mod dlls) | `lib/${pname}/`                               |
| arch-independent private data                            | `share/${pname}/`                             |
| vendored dependency headers / static libs                | nowhere — delete in `postInstall`             |

Strict FHS would put the binary of an app dir under `libexec/`, but these ports
require assets adjacent to the executable, and nixpkgs' own precedents for this
package family (`sm64coopdx`, `starship-sf64`) use a whole app dir under
`share/${pname}/`. Matching that convention keeps our expressions upstreamable.

## Making the binary find its files

- Ports using `SDL_GetBasePath()` (or anything `/proc/self/exe`-based) resolve
  through symlinks to the real binary, so `bin/foo -> ../share/${pname}/foo` is
  transparent — the game finds assets next to the real file (soh, 2s2h,
  dusklight).
- Wrappers referencing absolute store paths (`makeWrapper`, `wrapProgram
  --run`) just point into the namespaced dir (wwrando, wrye-bash).
- CWD-relative apps get `makeWrapper --chdir $out/share/${pname}` (nixpkgs
  `sm64coopdx`).
- Engine/plugin search paths go through env vars in the wrapper
  (`XASH3D_RODIR`, `LD_LIBRARY_PATH` for by-soname dlopen).

## Checking a package

```console
$ find $(nix build --no-link --print-out-paths .#foo) -mindepth 1 -maxdepth 2
```

`bin/` should contain only executables; the top levels of `lib/` and `share/`
should contain only namespaced directories and the standard trees (darwin
bundles add `Applications/`). Anything else will collide with some future
package.

`meta.priority` is for genuinely interchangeable tools; it is not a fix for
layout collisions — it only hides them by shadowing one package's files.

## Precedents

- Good: nixpkgs `sm64coopdx` (`share/sm64coopdx` + `--chdir` wrapper),
  `starship-sf64` (`share/starship-sf64`).
- Bad: nixpkgs `shipwright`'s flat `lib/` dump (collides with any fork), and
  the `zelda64recomp`/`mariokart64recomp` pair, which ship identical
  `share/assets` + `share/recompcontrollerdb.txt` paths and cannot coexist in
  a strict profile.
