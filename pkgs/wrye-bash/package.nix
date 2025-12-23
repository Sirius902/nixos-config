{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  python3,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  nix-update-script,
}: let
  taglistInfo = {
    Enderal = {
      repository = "enderal";
      hash = "sha256-5pIzHepPhSt5pkVkKa2eWsImJ7km2n5yQ+RXfhSdfik=";
    };
    Fallout3 = {
      repository = "fallout3";
      hash = "sha256-CDAy+Kf5bvKwqZocQ390HIyMOudqSog+g8k/+MJqMaY=";
    };
    FalloutNV = {
      repository = "falloutnv";
      hash = "sha256-Ykcnkoj6rc5NJPmVc4OnjvVRX2sXtaMjwf2vyqxWOMw=";
    };
    Fallout4 = {
      repository = "fallout4";
      hash = "sha256-xW2iIoEZgQIQKeYUgvVQhsJfazLMGSLpL/Sv1FSRs7c=";
    };
    Morrowind = {
      repository = "morrowind";
      hash = "sha256-/9NrwI31VWXprV8Xm3L/5T5EBMBuyMRnc97+NUovacY=";
    };
    Oblivion = {
      repository = "oblivion";
      hash = "sha256-xphW9BLd6JIw1jvCaj1A5F8S55es5PTE3hnGcF/hFv8=";
    };
    Skyrim = {
      repository = "skyrim";
      hash = "sha256-NwaQgUTJBD4xT7llsNLNC/XeoT1HxMzXDm+Yx5oa7GI=";
    };
    SkyrimSE = {
      repository = "skyrimse";
      hash = "sha256-rBwvKtFTZjl51u2BOSSTwX6nHxmu34gYysunZWX1sFw=";
    };
    Starfield = {
      repository = "starfield";
      hash = "sha256-bOX25usKTOwEjG61jIqlcvGJV9itKLFDcV4QE7FUgTs=";
    };
  };

  taglists =
    lib.mapAttrs (
      name: info:
        fetchurl {
          inherit (info) hash;
          name = "${info.repository}-masterlist.yaml";
          url = "https://raw.githubusercontent.com/loot/${info.repository}/v0.26/masterlist.yaml";
        }
    )
    taglistInfo;

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
      ./default-ini-fix.patch
      ./no-internet.patch
    ];

    nativeBuildInputs = [
      copyDesktopItems
      makeWrapper
    ];

    buildInputs = [
      python
    ];

    buildPhase = ''
      runHook preBuild

      ${python.interpreter} scripts/compile_l10n.py
      ${python.interpreter} -O -m compileall Mopy/bash

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
        --prefix PYTHONPATH : "$PYTHONPATH" \
        --add-flags "'$out/lib/wrye-bash/Mopy/Wrye Bash Launcher.pyw'"

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (
          game: taglist: "install -Dm644 ${taglist} $out/lib/wrye-bash/Mopy/taglists/${game}/taglist.yaml"
        )
        taglists)}

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
      license = lib.licenses.gpl3;
      platforms = lib.platforms.linux;
      maintainers = [];
    };
  })
