# Yoinked from https://github.com/NixOS/nixpkgs/pull/313013.
# https://github.com/NixOS/nixpkgs/blob/8dccd27f0feef3b0c1bb21a0b86e428a45a8be3c/pkgs/by-name/n6/n64recomp/package.nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  zip,
  unzip,
  makeWrapper,
  installShellFiles,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "n64recomp";
  version = "0-unstable-2025-09-07";

  src = fetchFromGitHub {
    owner = "N64Recomp";
    repo = "N64Recomp";
    rev = "6888c1f1df03349906acdec1a7ed3b308c86020c";
    hash = "sha256-xIpbGtnGyK+UYBBk8/+33H/oFzZKstGCv8Q/OF04ukE=";
    fetchSubmodules = true;
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    makeWrapper
    installShellFiles
  ];

  installPhase = ''
    runHook preInstall

    installBin {N64Recomp,RSPRecomp,RecompModTool}
    install -Dm644 -t $out/share/licenses/n64recomp ../LICENSE

    wrapProgram $out/bin/RecompModTool \
      --prefix PATH : ${zip}/bin \
      --prefix PATH : ${unzip}/bin

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--version-regex=(0-unstable-.*)"
    ];
  };

  meta = {
    description = "Tool to statically recompile N64 games into native executables";
    homepage = "https://github.com/N64Recomp/N64Recomp";
    license = with lib.licenses; [
      # N64Recomp
      mit

      # reverse engineering
      unfree
    ];
    maintainers = with lib.maintainers; [qubitnano];
    mainProgram = "N64Recomp";
    platforms = lib.platforms.linux;
  };
})
