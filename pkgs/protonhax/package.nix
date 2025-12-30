# https://github.com/NixOS/nixpkgs/pull/369861#issuecomment-2735586611
{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  steam-run,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "protonhax";
  version = "1.0.5";

  src = fetchFromGitHub {
    owner = "jcnils";
    repo = "protonhax";
    tag = finalAttrs.version;
    sha256 = "sha256-5G4MCWuaF/adSc9kpW/4oDWFFRpviTKMXYAuT2sFf9w=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp protonhax $out/bin
  '';

  postFixup = ''
    sed -i '1s/#!/#!${lib.escape ["/"] (lib.getExe steam-run)} /' $out/bin/protonhax
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Tool to help running other programs (i.e. Cheat Engine) inside Steam's proton";
    homepage = "https://github.com/jcnils/protonhax";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [pneg];
    mainProgram = "protonhax";
  };
})
