{
  lib,
  ghidra,
  gradle,
  fetchFromGitHub,
  ant,
  nix-update-script,
}: let
  version = "1.3.0-unstable-2025-12-15";
  self = ghidra.buildGhidraExtension {
    pname = "GameCubeLoader";
    inherit version;

    src = fetchFromGitHub {
      owner = "Cuyler36";
      repo = "Ghidra-GameCube-Loader";
      rev = "c61f08fdddfb655f2f1fd39dc53d8220530c8b52";
      hash = "sha256-w/onDdTSl6MidJL56e6sozOS9OsVwBhfCm3N1uGLmGQ=";
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
