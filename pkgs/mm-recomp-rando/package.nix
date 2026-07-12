{
  lib,
  stdenv,
  fetchFromGitHub,
  llvmPackages,
  n64recomp,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "mm-recomp-rando";
  version = "0-unstable-2026-02-28";

  src = fetchFromGitHub {
    owner = "RecompRando";
    repo = "MMRecompRando";
    rev = "25ae8d785b17e1297c3bc9b6c3cd2c262bc23411";
    hash = "sha256-p0gE2W+wG88uDuQTM7AxvVAs0CjdMCHJQ8YwuFrdsFY=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    llvmPackages.clang-unwrapped
    llvmPackages.lld
    n64recomp
  ];

  dontConfigure = true;

  makeFlags = [
    "CC=${lib.getExe' llvmPackages.clang-unwrapped "clang"}"
    "LD=${lib.getExe' llvmPackages.lld "ld.lld"}"
    "MOD_TOOL=${lib.getExe' n64recomp "RecompModTool"}"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 -t $out/share/mm-recomp-rando mm_recomp_rando/*.nrm

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--version-regex=(0-unstable-.*)"
    ];
  };

  meta = {
    homepage = "https://github.com/RecompRando/MMRecompRando";
    description = "Archipelago randomizer mod for Majora's Mask: Recompiled";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
  };
})
