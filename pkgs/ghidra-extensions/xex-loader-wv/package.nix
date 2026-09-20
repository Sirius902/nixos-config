{
  lib,
  ghidra,
  gradle,
  fetchFromGitHub,
  ant,
  nix-update-script,
}: let
  version = "12.1.3-unstable-2026-09-20";
  self = ghidra.buildGhidraExtension rec {
    pname = "XEXLoaderWV";
    inherit version;

    src = fetchFromGitHub {
      owner = "zeroKilo";
      repo = "XEXLoaderWV";
      rev = "4bcf58da4caa5260644fc19f5eef5ccde3b7ff46";
      hash = "sha256-FqBiBog4eBT48sH5dhg9mZhxZFHOiZ+kM7qOlz9Exmw=";
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
