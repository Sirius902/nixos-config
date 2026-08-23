{
  lib,
  ghidra,
  gradle,
  fetchFromGitHub,
  ant,
  nix-update-script,
}: let
  version = "12.1.2-unstable-2026-08-01";
  self = ghidra.buildGhidraExtension rec {
    pname = "XEXLoaderWV";
    inherit version;

    src = fetchFromGitHub {
      owner = "zeroKilo";
      repo = "XEXLoaderWV";
      rev = "edbceeba2c1da5065abd3ea02f5d2e2ca445f714";
      hash = "sha256-sJLANC+Bnnxjzhp6S1HL7vPSMOWOgPkp5AnuDdNn61M=";
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
      maintainers = with lib.maintainers; [sirius902];
      platforms = lib.platforms.unix;
    };
  };
in
  self
