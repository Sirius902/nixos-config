{
  lib,
  kytyps5_chenxiao,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  qt6,
}:
kytyps5_chenxiao.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "kytyps5-qtlauncher-chenxiao";

  postPatch =
    prevAttrs.postPatch
    + ''
      # The launcher treats its own and the emulator's directory as a writable install root.
      substituteInPlace src/launcher/src/mainDialog.cpp \
        --replace-fail "QDir search_dir(QApplication::applicationDirPath());" "QDir search_dir(QDir::currentPath());"
      substituteInPlace src/launcher/src/patchesDialog.cpp \
        --replace-fail "QDir(QCoreApplication::applicationDirPath())" "QDir(QDir::currentPath())"

      # The emulator comes from kytyps5_chenxiao.
      substituteInPlace src/launcher/CMakeLists.txt \
        --replace-fail "add_dependencies(launcher kyty_emulator)" ""
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

    # The performance paths stay off unless these are set; run_ds.sh is where the fork keeps them.
    mapfile -t switches < <(grep -E '^export KYTY_' ../tools/local/run_ds.sh)
    if (( ''${#switches[@]} == 0 )); then
      echo "error: no KYTY_ switches exported by tools/local/run_ds.sh" >&2
      exit 1
    fi
    switchArgs=()
    for switch in "''${switches[@]}"; do
      switchArgs+=(--run "$switch")
    done

    # Qt derives the Wayland app_id from the real executable's name.
    install -Dm755 launcher/launcher $out/libexec/${finalAttrs.pname}/${finalAttrs.meta.mainProgram}
    makeShellWrapper $out/libexec/${finalAttrs.pname}/${finalAttrs.meta.mainProgram} $out/bin/${finalAttrs.meta.mainProgram} \
      --run 'datadir="''${XDG_DATA_HOME:-$HOME/.local/share}/${kytyps5_chenxiao.pname}"' \
      --run 'mkdir -p "$datadir"' \
      --run 'ln -sf ${lib.getExe kytyps5_chenxiao} "$datadir/kyty_emulator"' \
      --run 'cd "$datadir"' \
      "''${switchArgs[@]}" \
      "''${qtWrapperArgs[@]}"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = finalAttrs.pname;
      desktopName = "KytyPS5 (chenxiao)";
      genericName = "PlayStation 5 Emulator";
      exec = finalAttrs.meta.mainProgram;
      categories = ["Game" "Emulator"];
      startupWMClass = finalAttrs.meta.mainProgram;
    })
  ];

  doInstallCheck = false;

  passthru = removeAttrs prevAttrs.passthru ["updateScript"];

  meta =
    prevAttrs.meta
    // {
      description = "${kytyps5_chenxiao.meta.description} (Qt launcher)";
      mainProgram = "kyty_launcher-chenxiao";
    };
})
