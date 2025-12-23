{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  p7zip,
  python3,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  nix-update-script,
  taglistsFn ? lib.id,
}: let
  taglists = taglistsFn (lib.mapAttrs (game: fetchArgs: fetchurl fetchArgs) (import ./taglists.nix));

  python = python3.withPackages (ps:
    with ps; [
      wxpython
      chardet
      lz4
      pyyaml
      vdf
      lxml
      packaging
      pyfiglet
      pymupdf
      requests
      send2trash
      websocket-client
      reflink
    ]);
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "wrye-bash";
    version = "314-unstable-2025-12-23";

    src = fetchFromGitHub {
      owner = "wrye-bash";
      repo = "wrye-bash";
      rev = "c9937dbeb9e5880ee5fbf6caf4e8a46792961fcb";
      hash = "sha256-LPSkgi7spgSoIpqQ1zhxcobieut9ui1IOwI4ZzXAtoA=";
    };

    patches = [
      # https://aur.archlinux.org/cgit/aur.git/plain/0001-Make-BashBugDump-work-globally.patch?h=wrye-bash
      ./0001-Make-BashBugDump-work-globally.patch
      ./0002-Don-t-use-internet-in-helpers-utils.py.patch
      ./0003-Write-bash_default.ini-to-config-directory.patch
    ];

    nativeBuildInputs = [
      copyDesktopItems
      makeWrapper
      python
    ];

    buildInputs = [
      p7zip
    ];

    postPatch = ''
      substituteInPlace Mopy/bash/basher/constants.py \
        --replace-fail "'bash.update_check.enabled': True" "'bash.update_check.enabled': False"
    '';

    buildPhase = ''
      runHook preBuild

      ${python.interpreter} scripts/compile_l10n.py

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,lib/wrye-bash}

      cp -r Mopy $out/lib/wrye-bash/
      rm -r $out/lib/wrye-bash/Mopy/bash/compiled
      rm -r $out/lib/wrye-bash/Mopy/bash/tests

      # Only the .mo files matter for an end-user build
      rm $out/lib/wrye-bash/Mopy/bash/l10n/*.po
      rm $out/lib/wrye-bash/Mopy/bash/l10n/template.pot

      makeWrapper ${python.interpreter} $out/bin/wrye-bash \
        --prefix PATH : ${lib.makeBinPath [p7zip]} \
        --add-flags "'$out/lib/wrye-bash/Mopy/Wrye Bash Launcher.pyw'"

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (
          game: taglist: "install -Dm644 ${taglist} $out/lib/wrye-bash/Mopy/taglists/${game}/taglist.yaml"
        )
        taglists)}

      ${python.interpreter} -O -m compileall $out/lib/wrye-bash/Mopy/bash

      install -Dm644 Mopy/bash/images/bash.svg $out/share/icons/hicolor/scalable/apps/wrye-bash.svg

      install -Dm644 LICENSE.md $out/share/licenses/wrye-bash/LICENSE.md
      install -Dm644 Mopy/LICENSE-THIRD-PARTY $out/share/licenses/wrye-bash/LICENSE-THIRD-PARTY

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "Wrye Bash";
        desktopName = "Wrye Bash";
        icon = "wrye-bash";
        exec = "wrye-bash";
        type = "Application";
        comment = finalAttrs.meta.description;
        categories = [
          "System"
          "FileTools"
          "FileManager"
          "X-ModManager"
        ];
      })
    ];

    passthru.updateScript = nix-update-script {
      extraArgs = ["--version=branch"];
    };

    meta = {
      homepage = "https://github.com/wrye-bash/wrye-bash";
      description = "A swiss army knife for modding Bethesda games.";
      mainProgram = "wrye-bash";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux;
      maintainers = with lib.maintainers; [
        # sirius902
      ];
    };
  })
