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
  version = "unstable-2025-08-29";

  src = fetchFromGitHub {
    owner = "N64Recomp";
    repo = "N64Recomp";
    rev = "6db56f597d1fd52f8f5439504c3de0a4e4e2bf37";
    hash = "sha256-M5VMyhOJ6fSOhxJ9iMp+yzCHbwnS6ZLC1y5HFO+SSOk=";
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
      "--version-regex"
      ".*(unstable-.*)"
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
