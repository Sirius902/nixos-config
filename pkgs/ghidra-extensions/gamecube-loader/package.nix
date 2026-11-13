{
  lib,
  ghidra,
  gradle,
  fetchFromGitHub,
  ant,
  nix-update-script,
}: let
  version = "1.3.1-unstable-2026-11-11";
  self = ghidra.buildGhidraExtension {
    pname = "GameCubeLoader";
    inherit version;

    src = fetchFromGitHub {
      owner = "Cuyler36";
      repo = "Ghidra-GameCube-Loader";
      rev = "bc17469a6e37c260b07e8c46f0c9bde2bd3e97dc";
      hash = "sha256-Ss3lHXlrencNwXD3tfVXdETolDgGtpIcCxof80NpCK8=";
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

      substituteInPlace src/main/java/gamecubeloader/rso/RSOHeader.java \
        --replace-fail \
        'public boolean IsValid(BinaryReader reader)' \
        'public boolean IsValid(BinaryReader reader) throws IOException'
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
      maintainers = with lib.maintainers; [sirius902];
      platforms = lib.platforms.unix;
    };
  };
in
  self
