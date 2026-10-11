{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  steamDisplayName = "Proton-Wineland";

  pname = "proton-wineland";
  version = "11.0-20261005";

  src = fetchzip {
    url = "https://github.com/nanomatters/proton-cachyos/releases/download/wineland-${finalAttrs.version}/proton-wineland-${finalAttrs.version}-x86_64.tar.xz";
    hash = "sha256-GTfrrIoNEesyXB5ZsQd/DEOw4VvZG+/9g4Uldq+RDzs=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  outputs = [
    "out"
    "steamcompattool"
  ];

  installPhase = ''
    runHook preInstall

    echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

    mkdir $steamcompattool
    ln -s $src/* $steamcompattool
    rm $steamcompattool/compatibilitytool.vdf
    cp $src/compatibilitytool.vdf $steamcompattool

    runHook postInstall
  '';

  # Steam maps games to their tool by internal name, so it can't carry the version.
  preFixup = ''
    substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
      --replace-fail "proton-wineland-${finalAttrs.version}-x86_64" "$steamDisplayName"
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--use-github-releases"
      "--version-regex=^wineland-(.*)$"
    ];
  };

  meta = {
    description = "Wayland-focused Proton-CachyOS fork for Steam Play";
    homepage = "https://github.com/nanomatters/proton-cachyos";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [sirius902];
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
