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
  version = "0-unstable-2026-08-04";

  src = fetchFromGitHub {
    owner = "RecompRando";
    repo = "MMRecompRando";
    rev = "27ed1ad0b7113e5e97564aac636852a5aff622f8";
    hash = "sha256-pm7TD44qYoWFk8yKrg9ma9UYxa2uSpNzbLi4zpQWAoE=";
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
    maintainers = with lib.maintainers; [sirius902];
    platforms = ["x86_64-linux"];
  };
})
