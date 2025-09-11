{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sdl_gamecontrollerdb";
  version = "0-unstable-2025-09-11";

  src = fetchFromGitHub {
    owner = "mdqinc";
    repo = "SDL_GameControllerDB";
    rev = "1961f86c06e03e7f80525ef16e85b330dd456436";
    hash = "sha256-jTJqrgxgUEbCP/32Vn1f71i55+xykHgWxApjdSwArWk=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 gamecontrollerdb.txt -t $out/share
    install -Dm644 LICENSE -t $out/share/licenses/sdl_gamecontrollerdb

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {extraArgs = ["--version=branch"];};

  meta = {
    description = "Community sourced database of game controller mappings to be used with SDL2 and SDL3 Game Controller functionality";
    homepage = "https://github.com/mdqinc/SDL_GameControllerDB";
    license = lib.licenses.zlib;
    maintainers = with lib.maintainers; [qubitnano];
    platforms = lib.platforms.all;
  };
})
