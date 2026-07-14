{
  lib,
  stdenv,
  fetchFromGitHub,
  python313,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  qt6,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "wwrando";
  version = "1.10.0";

  src = fetchFromGitHub {
    owner = "LagoLunatic";
    repo = "wwrando";
    tag = finalAttrs.version;
    hash = "sha256-GbjvTGUJcyJBIvBs71fIUe/VY2K2cC97n9iRT/Z0TzU=";
  };

  patches = [./loose-version.patch];

  pythonEnv = python313.withPackages (ps:
    with ps; [
      appdirs
      certifi
      pillow
      pyside6
      pyyaml
    ]);

  requirementsHash = "5b05925483662c66d6bb034a69783dcd515aa90c1e042a1d688cdd276ec70673";

  prunePaths = toString [
    ".github"
    ".gitattributes"
    ".gitignore"
    ".gitmodules"
    "build.bat"
    "build.py"
    "profile.bat"
    "profile_ui.bat"
    "requirements_full.txt"
    "wwrando.spec"
  ];

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
  ];

  dontWrapQtApps = true;

  postPatch = ''
    actualHash=$(sha256sum requirements.txt | cut -d" " -f1)
    if [[ "$actualHash" != "$requirementsHash" ]]; then
      echo "error: Python requirements changed upstream"
      echo "review requirements.txt, then update pythonEnv and requirementsHash in package.nix"
      exit 1
    fi

    substituteInPlace wwrando_paths.py \
      --replace-fail "IS_RUNNING_FROM_SOURCE = True" "IS_RUNNING_FROM_SOURCE = False" \
      --replace-fail 'SETTINGS_PATH = os.path.join(RANDO_ROOT_PATH, "settings.txt")' 'SETTINGS_PATH = os.path.join(".", "settings.txt")' \
      --replace-fail 'CUSTOM_MODELS_PATH = os.path.join(RANDO_ROOT_PATH, "models")' 'CUSTOM_MODELS_PATH = os.path.join(".", "models")'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/${finalAttrs.pname}
    cp -r . $out/share/${finalAttrs.pname}
    for p in $prunePaths; do
      rm -rf "$out/share/${finalAttrs.pname}/$p"
    done

    $pythonEnv/bin/python -m compileall -q -j $NIX_BUILD_CORES $out/share/${finalAttrs.pname}

    makeShellWrapper $pythonEnv/bin/python $out/bin/${finalAttrs.pname} \
      --add-flags "$out/share/${finalAttrs.pname}/wwrando.py" \
      --run 'datadir="''${XDG_DATA_HOME:-$HOME/.local/share}/${finalAttrs.pname}"' \
      --run 'mkdir -p "$datadir/models"' \
      --run 'ln -sf "${placeholder "out"}/share/${finalAttrs.pname}/README.md" "$datadir/README.md"' \
      --run 'ln -sf "${placeholder "out"}/share/${finalAttrs.pname}/models/"* "$datadir/models/"' \
      --run 'cd "$datadir"' \
      "''${qtWrapperArgs[@]}"

    runHook installIcon

    runHook postInstall
  '';

  installIcon = ''
    install -Dm644 "assets/swift sail icon.png" \
      $out/share/icons/hicolor/48x48/apps/${finalAttrs.pname}.png
  '';

  desktopItem = makeDesktopItem {
    name = finalAttrs.pname;
    icon = finalAttrs.pname;
    desktopName = "Wind Waker Randomizer";
    categories = ["Game"];
    type = "Application";
    exec = finalAttrs.pname;
  };

  desktopItems = [finalAttrs.desktopItem];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Randomizer for The Legend of Zelda: The Wind Waker";
    homepage = "https://lagolunatic.github.io/wwrando";
    changelog = "https://github.com/LagoLunatic/wwrando/releases/tag/${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = finalAttrs.pname;
    maintainers = with lib.maintainers; [
      # sirius902
    ];
    platforms = lib.platforms.linux;
  };
})
