# Yoinked from https://github.com/NixOS/nixpkgs/pull/313013.
# https://github.com/NixOS/nixpkgs/blob/8dccd27f0feef3b0c1bb21a0b86e428a45a8be3c/pkgs/by-name/z6/z64decompress/package.nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  installShellFiles,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "z64decompress";
  version = "1.0.3-unstable-2023-12-21";

  src = fetchFromGitHub {
    owner = "z64tools";
    repo = "z64decompress";
    rev = "e2b3707271994a2a1b3afc6c3997a7cf6b479765";
    hash = "sha256-PHiOeEB9njJPsl6ScdoDVwJXGqOdIIJCZRbIXSieBIY=";
  };

  nativeBuildInputs = [installShellFiles];

  makeFlags = ["CC=${stdenv.cc.targetPrefix}cc"];

  installPhase = ''
    runHook preInstall

    installBin z64decompress
    install -Dm644 -t $out/share/licenses/z64decompress LICENSE

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "v(.*)"
    ];
  };

  meta = {
    description = "Zelda 64 rom decompressor";
    homepage = "https://github.com/z64tools/z64decompress";
    license = with lib.licenses; [
      gpl3Only

      # Reverse engineering
      unfree
    ];
    maintainers = with lib.maintainers; [qubitnano];
    mainProgram = "z64decompress";
    platforms = lib.platforms.linux;
    hydraPlatforms = [];
  };
})
