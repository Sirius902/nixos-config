{
  lib,
  ghidra,
  gradle,
  fetchFromGitHub,
  ant,
  nix-update-script,
}: let
  version = "1.2.5-unstable-2024-11-24";
  self = ghidra.buildGhidraExtension {
    pname = "GameCubeLoader";
    inherit version;

    src = fetchFromGitHub {
      owner = "Cuyler36";
      repo = "Ghidra-GameCube-Loader";
      rev = "0ff5e888526cd8cbc03660445c0dcd1105c8883a";
      hash = "sha256-kwgm3xf1VLm6N4icY2LHsL01mxqqR5djUd/Bw2hkFTg=";
    };

    nativeBuildInputs = [ant];

    postPatch = ''
      substituteInPlace build.gradle \
        --replace-fail '-''${getGitHash()}' '-${version}'

      # FUTURE(Sirius902) git patch for these?
      substituteInPlace data/buildLanguage.xml \
        --replace-fail \
        '<import file="../.antProperties.xml" optional="false" />' \
        '<import file="../.antProperties.xml" optional="true" />'

      substituteInPlace data/buildLanguage.xml \
        --replace-fail \
        '<arg value="-i"/>' \
        ""

      substituteInPlace data/buildLanguage.xml \
        --replace-fail \
        '<arg value="sleighArgs.txt"/>' \
        ""
    '';

    configurePhase = ''
      runHook preConfigure

      # this doesn't really compile, it compresses sinc into sla
      pushd data
      ant -f buildLanguage.xml -Dghidra.install.dir=${ghidra}/lib/ghidra sleighCompile
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
      description = "Nintendo GameCube Binary Loader for Ghidra";
      homepage = "https://github.com/Cuyler36/Ghidra-GameCube-Loader";
      license = lib.licenses.asl20;
      # FUTURE(Sirius902) Put me here?
      maintainers = [];
      platforms = lib.platforms.unix;
    };
  };
in
  self
