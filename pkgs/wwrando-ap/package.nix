{
  wwrando,
  fetchFromGitHub,
  python313,
  imagemagick,
  nix-update-script,
}: let
  gclib = python313.pkgs.callPackage ./python-modules/gclib {};
in
  wwrando.overrideAttrs (finalAttrs: prevAttrs: {
    pname = "wwrando-ap";
    version = "2.5.2";
    src = fetchFromGitHub {
      owner = "tanjo3";
      repo = "wwrando";
      tag = "ap_${finalAttrs.version}";
      hash = "sha256-yCH7u6V0ERD/5yroS0x4xGa54Ms0m/jtgwh8bYoGzAI=";
    };

    patches = [];

    pythonEnv = python313.withPackages (ps:
      (with ps; [
        appdirs
        certifi
        pillow
        pyside6
        qtpy
        ruamel-yaml
        tqdm
      ])
      ++ [gclib]);

    requirementsHash = "6e128755c71748172a98298f3d7be056fdd38c03d2c85be27c341e9eca95bb73";

    postPatch =
      prevAttrs.postPatch
      + ''
        substituteInPlace options/base_options.py \
          --replace-fail \
          "from dataclasses import fields, MISSING, Field, _recursive_repr, _FIELDS, _FIELD, asdict" \
          "from dataclasses import fields, MISSING, Field, _FIELDS, _FIELD, asdict; from reprlib import recursive_repr; _recursive_repr = recursive_repr()"
      '';

    prunePaths =
      prevAttrs.prunePaths
      + " "
      + toString [
        "docs"
        "gclib"
        "mkdocs-gh-pages.yml"
        "mkdocs.yml"
        "pyrightconfig.json"
        "pytest.ini"
        "requirements_qt5.txt"
        "requirements_qt5_full.txt"
        "test"
      ];

    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [imagemagick];

    installIcon = ''
      mkdir -p $out/share/icons/hicolor
      frames=$(magick identify -format "%[scene] %[width] %[height]\n" assets/icon.ico)
      while read -r scene width height; do
        mkdir -p $out/share/icons/hicolor/''${width}x''${height}/apps
        magick "assets/icon.ico[$scene]" \
               $out/share/icons/hicolor/''${width}x''${height}/apps/${finalAttrs.pname}.png
      done <<< "$frames"
    '';

    desktopItem = prevAttrs.desktopItem.override {
      desktopName = "Wind Waker Archipelago Randomizer";
    };

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = nix-update-script {
          extraArgs = ["--version-regex=ap_(.*)"];
        };
      };

    meta = prevAttrs.meta // {changelog = "https://github.com/tanjo3/wwrando/releases/tag/${finalAttrs.version}";};
  })
