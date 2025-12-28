{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sdl_gamecontrollerdb";
  version = "0-unstable-2025-12-28";

  src = fetchFromGitHub {
    owner = "mdqinc";
    repo = "SDL_GameControllerDB";
    rev = "5e686a3e781937e7f43138440a032f47140d0624";
    hash = "sha256-tXD13rCFS1Vpt5SucxFp9E3+bURVP000PoKisA7PiZw=";
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
