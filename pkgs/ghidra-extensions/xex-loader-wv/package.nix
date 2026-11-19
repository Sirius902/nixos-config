{
  lib,
  ghidra,
  gradle,
  fetchFromGitHub,
  ant,
  nix-update-script,
}: let
  version = "12.2-unstable-2026-11-17";
  self = ghidra.buildGhidraExtension rec {
    pname = "XEXLoaderWV";
    inherit version;

    src = fetchFromGitHub {
      owner = "zeroKilo";
      repo = "XEXLoaderWV";
      rev = "a8a1d0d3923d25163c5a401f8198236075129571";
      hash = "sha256-ixYHTw+ELL4KgJ6L2M2X/H5v5NARvGTU6pYY0n+QKGA=";
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
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [sirius902];
      platforms = lib.platforms.unix;
    };
  };
in
  self
