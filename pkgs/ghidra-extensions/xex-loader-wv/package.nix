{
  lib,
  ghidra,
  gradle,
  fetchFromGitHub,
  ant,
  nix-update-script,
}: let
  version = "12.0.4-unstable-2026-03-29";
  self = ghidra.buildGhidraExtension rec {
    pname = "XEXLoaderWV";
    inherit version;

    src = fetchFromGitHub {
      owner = "zeroKilo";
      repo = "XEXLoaderWV";
      rev = "978755ca77eeaa992080d86b4a6d98633314e90b";
      hash = "sha256-guv0xCSjcX72lSgEyV/fLDigWlSxe7luEJ2gQJVNKpc=";
    };

    sourceRoot = "${src.name}/XEXLoaderWV";

    nativeBuildInputs = [ant];

    configurePhase = ''
      runHook preConfigure

      # this doesn't really compile, it compresses sinc into sla
      pushd data
      ant -f build.xml -Dghidra.install.dir=${ghidra}/lib/ghidra sleighCompile
      popd

      runHook postConfigure
    '';

    gradleBuildTask = "buildExtension";

    __darwinAllowLocalNetworking = true;

    mitmCache = gradle.fetchDeps {
      pkg = self;
      data = ./deps.json;
    };

    passthru.updateScript = nix-update-script {extraArgs = ["--version=branch"];};

    meta = {
      description = "Ghidra Loader Module for X360 XEX Files";
      homepage = "https://github.com/zeroKilo/XEXLoaderWV";
      license = lib.licenses.unlicense;
      # FUTURE(Sirius902) Put me here?
      maintainers = [];
      platforms = lib.platforms.unix;
    };
  };
in
  self
