{
  lib,
  ghidra,
  gradle,
  fetchFromGitHub,
  ant,
  nix-update-script,
}: let
  version = "12.1-unstable-2026-06-05";
  self = ghidra.buildGhidraExtension rec {
    pname = "XEXLoaderWV";
    inherit version;

    src = fetchFromGitHub {
      owner = "zeroKilo";
      repo = "XEXLoaderWV";
      rev = "d0af801aee083c86950b90c3db78b2e1c642067f";
      hash = "sha256-RHKXHE2zhfJGR6mj9I8up7VIsndHv1llDkm5MwPAKAQ=";
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
