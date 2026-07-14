{
  lib,
  stdenv,
  fetchFromGitHub,
  python312,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  enemizer-cli,
  sni,
  nix-update-script,
}: let
  python = python312.override {
    self = python;
    packageOverrides = pfinal: pprev: {
      asyncgui = pfinal.callPackage ./python-modules/asyncgui {};
      asynckivy = pfinal.callPackage ./python-modules/asynckivy {};
      dolphin-memory-engine = pfinal.callPackage ./python-modules/dolphin-memory-engine {};
      factorio-rcon-py = pfinal.callPackage ./python-modules/factorio-rcon-py {};
      kivymd = pfinal.callPackage ./python-modules/kivymd {};
      maseya-z3pr = pfinal.callPackage ./python-modules/maseya-z3pr {};
      pkg-resources = pfinal.callPackage ./python-modules/pkg-resources {};
      pyevermizer = pfinal.callPackage ./python-modules/pyevermizer {};
      pymem = pfinal.callPackage ./python-modules/pymem {};
      pymemoryeditor = pfinal.callPackage ./python-modules/pymemoryeditor {};
      pyshortcuts = pfinal.callPackage ./python-modules/pyshortcuts {};
      setuptools-cmake-helper = pfinal.callPackage ./python-modules/setuptools-cmake-helper {};
      websockets = pfinal.callPackage ./python-modules/websockets {};
      xxtea = pfinal.callPackage ./python-modules/xxtea {};
      zilliandomizer = pfinal.callPackage ./python-modules/zilliandomizer {};
    };
  };

  requirements = ps:
    with ps; [
      aiohttp
      bsdiff4
      certifi
      colorama
      cymem
      cython
      dolphin-memory-engine
      factorio-rcon-py
      jellyfish
      jinja2
      kivy
      kivymd
      loguru
      maseya-z3pr
      mpyq
      nest-asyncio
      orjson
      pathspec
      pkg-resources
      platformdirs
      portpicker
      protobuf
      pyevermizer
      pymem
      pymemoryeditor
      pyshortcuts
      pyyaml
      schema
      setuptools
      typing-extensions
      websockets
      xxtea
      zilliandomizer
    ];

  pythonEnv = python.withPackages requirements;
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "archipelago";
    version = "0.6.7";

    src = fetchFromGitHub {
      owner = "ArchipelagoMW";
      repo = "Archipelago";
      tag = finalAttrs.version;
      hash = "sha256-v/EXsZDImi32/P6rjqqPMKMBoiUEn/8z7lBjr8MTrvM=";
    };

    patches = [./user-data-umask.patch];

    nativeBuildInputs = [
      copyDesktopItems
      makeWrapper
      pythonEnv
    ];

    postPatch = ''
      requirementsHash=$(cat requirements.txt worlds/*/requirements.txt | sha256sum | cut -d' ' -f1)
      if [[ "$requirementsHash" != "f846b7ed556f52e8a2f2dc9dee5b767685ef536eb2a90438a0d46ce9468ed2ff" ]]; then
        echo "error: Python requirements changed upstream"
        echo "review requirements.txt and worlds/*/requirements.txt, then update"
        echo "the requirements list and hash in package.nix"
        exit 1
      fi
    '';

    buildPhase = ''
      runHook preBuild

      cythonize -b -i _speedups.pyx
      rm -rf build _speedups.c

      export SKIP_REQUIREMENTS_UPDATE=1
      ${pythonEnv.interpreter} -c '
      import json
      import os
      import shutil

      import Utils
      from Options import generate_yaml_templates

      os.makedirs("Players/Templates", exist_ok=True)
      generate_yaml_templates("Players/Templates", False)
      shutil.copyfile("meta.yaml", "Players/Templates/meta.yaml")

      manifest = {
          "buildtime": "1980-01-01 00:00:00",
          "hashes": {},
          "version": list(Utils.version_tuple),
      }
      with open("manifest.json", "w") as f:
          json.dump(manifest, f, indent=4)
      '
      rm -rf custom_worlds host.yaml

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/archipelago
      cp -r . $out/share/archipelago
      rm -r \
        $out/share/archipelago/.dockerignore \
        $out/share/archipelago/.gitattributes \
        $out/share/archipelago/.github \
        $out/share/archipelago/.gitignore \
        $out/share/archipelago/Dockerfile \
        $out/share/archipelago/WebHost.py \
        $out/share/archipelago/WebHostLib \
        $out/share/archipelago/deploy \
        $out/share/archipelago/inno_setup.iss \
        $out/share/archipelago/test

      ln -s ${enemizer-cli}/lib/enemizer-cli $out/share/archipelago/EnemizerCLI
      mkdir $out/share/archipelago/SNI
      ln -s ${lib.getExe sni} $out/share/archipelago/SNI/sni
      ln -s ${sni}/share/sni/apps.yaml $out/share/archipelago/SNI/apps.yaml
      ln -s ${sni}/share/sni/lua $out/share/archipelago/SNI/lua

      ${pythonEnv.interpreter} -m compileall -q -j $NIX_BUILD_CORES $out/share/archipelago

      makeWrapper ${pythonEnv.interpreter} $out/bin/archipelago \
        --set-default SKIP_REQUIREMENTS_UPDATE 1 \
        --add-flags "$out/share/archipelago/Launcher.py"
      makeWrapper ${pythonEnv.interpreter} $out/bin/archipelago-generate \
        --set-default SKIP_REQUIREMENTS_UPDATE 1 \
        --add-flags "$out/share/archipelago/Generate.py"
      makeWrapper ${pythonEnv.interpreter} $out/bin/archipelago-server \
        --set-default SKIP_REQUIREMENTS_UPDATE 1 \
        --add-flags "$out/share/archipelago/MultiServer.py"
      makeWrapper ${pythonEnv.interpreter} $out/bin/archipelago-text-client \
        --set-default SKIP_REQUIREMENTS_UPDATE 1 \
        --add-flags "$out/share/archipelago/CommonClient.py"

      install -Dm644 data/icon.png $out/share/icons/hicolor/512x512/apps/archipelago.png

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "archipelago";
        desktopName = "Archipelago";
        genericName = "Multi-Game Randomizer";
        icon = "archipelago";
        exec = "archipelago";
        type = "Application";
        comment = finalAttrs.meta.description;
        categories = ["Game"];
      })
    ];

    passthru = {
      updateScript = nix-update-script {};

      tests.pytest = stdenv.mkDerivation {
        name = "archipelago-pytest";
        inherit (finalAttrs) src patches;
        nativeBuildInputs = [
          (python.withPackages (ps: requirements ps ++ [ps.pytest ps.pytest-xdist]))
        ];
        buildPhase = ''
          runHook preBuild

          export HOME=$TMPDIR SKIP_REQUIREMENTS_UPDATE=1
          cythonize -b -i _speedups.pyx
          python -c 'from settings import get_settings; get_settings()'
          pytest -n auto \
            --ignore=test/benchmark \
            --ignore=test/cpp \
            --ignore=test/hosting \
            --ignore=test/webhost \
            --ignore=worlds/factorio/test_file_validation.py

          runHook postBuild
        '';
        installPhase = "touch $out";
      };
    };

    meta = {
      description = "Multi-game randomizer and server";
      homepage = "https://archipelago.gg";
      license = lib.licenses.mit;
      mainProgram = "archipelago";
      sourceProvenance = [
        lib.sourceTypes.fromSource
        lib.sourceTypes.binaryNativeCode
      ];
      platforms = ["x86_64-linux"];
    };
  })
