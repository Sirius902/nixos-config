{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  cmake,
  ninja,
  python3,
  ncurses,
  runCommand,
  versionCheckHook,
  enableTerminfo ? true,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "clang-format";
  version = "14.0.6";

  src = fetchurl {
    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-${finalAttrs.version}/llvm-project-${finalAttrs.version}.src.tar.xz";
    hash = "sha256-izz9e8aVvWzqDzf1PwmB80+HSW554lKYdP0DovndOoo=";
  };

  # Nothing else in the monorepo is needed: clang-format is built from llvm/
  # and clang/, which in LLVM 14 still use the top-level cmake/ modules. The
  # test trees are only read with LLVM_INCLUDE_TESTS.
  unpackCmd = ''
    tar -xf "$curSrc" \
      --exclude=llvm-project-${finalAttrs.version}.src/{llvm,clang}/{test,unittests} \
      llvm-project-${finalAttrs.version}.src/{cmake,llvm,clang}
  '';

  sourceRoot = "llvm-project-${finalAttrs.version}.src/llvm";

  patches = [
    # [ADT] Add `<cstdint>` to SmallVector, needed with GCC 15.
    (fetchpatch {
      url = "https://github.com/llvm/llvm-project/commit/7e44305041d96b064c197216b931ae3917a34ac1.diff";
      stripLen = 1;
      hash = "sha256-1htuzsaPHbYgravGc1vrR8sqpQ/NSQ8PUZeAU8ucCFk=";
    })
  ];

  outputs = [
    "out"
    "python"
  ];

  nativeBuildInputs = [
    cmake
    python3
    ninja
  ];

  buildInputs =
    [
      # Interpreter for the python output's scripts; with strictDeps,
      # patchShebangs only looks it up in buildInputs.
      python3
    ]
    ++ lib.optional enableTerminfo ncurses;

  strictDeps = true;

  __structuredAttrs = true;

  cmakeBuildType = "Release";

  cmakeFlags = [
    (lib.cmakeFeature "LLVM_ENABLE_PROJECTS" "clang")
    (lib.cmakeFeature "LLVM_TARGETS_TO_BUILD" "host")
    (lib.cmakeFeature "LLVM_HOST_TRIPLE" stdenv.hostPlatform.config)
    (lib.cmakeBool "LLVM_ENABLE_TERMINFO" enableTerminfo)
    # Support's compression is never used by clang-format, so this keeps zlib
    # out of the closure.
    (lib.cmakeBool "LLVM_ENABLE_ZLIB" false)
    # These trees are not unpacked.
    (lib.cmakeBool "LLVM_INCLUDE_TESTS" false)
    (lib.cmakeBool "LLVM_INCLUDE_BENCHMARKS" false)
  ];

  ninjaFlags = ["clang-format"];
  installTargets = ["install-clang-format"];

  postInstall = ''
    mkdir -p $python/bin $python/share/clang/
    mv $out/bin/git-clang-format $python/bin
    mv $out/share/clang/*.py $python/share/clang
    patchShebangs $python/bin
    patchShebangs $python/share/clang/
  '';

  # Only the python output may depend on python3.
  outputChecks.out.disallowedRequisites = [python3];

  doInstallCheck = true;
  nativeInstallCheckInputs = [versionCheckHook];

  passthru.tests.smoke =
    runCommand "clang-format-smoke-test" {nativeBuildInputs = [finalAttrs.finalPackage];}
    ''
      echo 'int  main( ){return 0;}' | clang-format --style=LLVM > formatted.cpp
      echo 'int main() { return 0; }' | diff -u - formatted.cpp
      touch $out
    '';

  meta = {
    homepage = "https://clang.llvm.org/docs/ClangFormat.html";
    description = "Tool to format C/C++/Java/JavaScript/JSON/Objective-C/Protobuf/C# code";
    # As nixpkgs' llvm_meta does for LLVM < 19.
    license = lib.licenses.ncsa;
    # See llvm/cmake/config-ix.cmake.
    platforms =
      lib.platforms.aarch64
      ++ lib.platforms.arm
      ++ lib.platforms.mips
      ++ lib.platforms.power
      ++ lib.platforms.s390x
      ++ lib.platforms.wasi
      ++ lib.platforms.x86
      ++ lib.platforms.riscv
      ++ lib.platforms.m68k
      ++ lib.platforms.loongarch64;
    identifiers.cpeParts.vendor = "llvm";
    mainProgram = "clang-format";
  };
})
