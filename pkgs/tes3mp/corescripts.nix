{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  tes3mp,
}:
stdenvNoCC.mkDerivation {
  pname = "tes3mp-corescripts";
  version = "0-unstable-2025-10-10";

  src = fetchFromGitHub {
    owner = "TES3MP";
    repo = "CoreScripts";
    rev = "3e397a11eaf7d0d4ff08df4bb9925e67748b4db8";
    hash = "sha256-945ie3yAdLC9d9Y5IxNYrn2nvn/oaxFKW2MgculqDjY=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r . $out/share/tes3mp-corescripts

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=${tes3mp.version}"
      "--version-regex=(0-unstable-.*)"
    ];
  };

  meta = {
    description = "Lua scripts that implement a TES3MP server's gameplay";
    homepage = "https://github.com/TES3MP/CoreScripts";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [sirius902];
    platforms = lib.platforms.all;
  };
}
