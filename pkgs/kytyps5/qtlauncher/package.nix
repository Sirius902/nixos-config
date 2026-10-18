{
  lib,
  kytyps5,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  qt6,
}:
kytyps5.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "kytyps5-qtlauncher";

  postPatch =
    prevAttrs.postPatch
    + ''
      # The launcher treats its own and the emulator's directory as a writable install root.
      substituteInPlace src/launcher/src/mainDialog.cpp \
        --replace-fail "QDir search_dir(QApplication::applicationDirPath());" "QDir search_dir(QDir::currentPath());"
      substituteInPlace src/launcher/src/cheatFile.cpp \
        --replace-fail "QDir(QCoreApplication::applicationDirPath())" "QDir(QDir::currentPath())"

      # The emulator comes from kytyps5.
      substituteInPlace src/launcher/CMakeLists.txt \
        --replace-fail "add_dependencies(launcher kyty_emulator stage_updater)" "add_dependencies(launcher stage_updater)"
    '';

  nativeBuildInputs =
    prevAttrs.nativeBuildInputs
    ++ [
      copyDesktopItems
      makeWrapper
      qt6.wrapQtAppsHook
    ];

  buildInputs =
    prevAttrs.buildInputs
    ++ [
      qt6.qtbase
      qt6.qtsvg
      qt6.qtwayland
    ];

  cmakeFlags =
    prevAttrs.cmakeFlags
    ++ [
      (lib.cmakeBool "KYTY_BUILD_LAUNCHER" true)
    ];

  ninjaFlags = ["launcher"];

  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    # Qt derives the Wayland app_id from the real executable's name.
    install -Dm755 launcher/kyty_launcher $out/libexec/${finalAttrs.pname}/kyty_launcher
    makeShellWrapper $out/libexec/${finalAttrs.pname}/kyty_launcher $out/bin/kyty_launcher \
      --run 'datadir="''${XDG_DATA_HOME:-$HOME/.local/share}/${kytyps5.pname}"' \
      --run 'mkdir -p "$datadir"' \
      --run 'ln -sf ${lib.getExe kytyps5} "$datadir/kyty_emulator"' \
      --run 'cd "$datadir"' \
      "''${qtWrapperArgs[@]}"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = finalAttrs.pname;
      desktopName = "KytyPS5";
      genericName = "PlayStation 5 Emulator";
      exec = "kyty_launcher";
      categories = ["Game" "Emulator"];
      startupWMClass = "kyty_launcher";
    })
  ];

  doInstallCheck = false;

  passthru = removeAttrs prevAttrs.passthru ["updateScript"];

  meta =
    prevAttrs.meta
    // {
      description = "${kytyps5.meta.description} (Qt launcher)";
      mainProgram = "kyty_launcher";
    };
})
