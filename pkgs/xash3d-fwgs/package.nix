{
  lib,
  fetchFromGitHub,
  stdenv,
  ensureNewerSourcesForZipFilesHook,
  python3,
  pkg-config,
  wafHook,
  SDL2,
  libx11,
  freetype,
  opusfile,
  libopus,
  libogg,
  libvorbis,
  bzip2,
  hlsdk-portable,
  makeWrapper,
  nix-update-script,
  # Options
  sdks ? [hlsdk-portable],
  buildServer ? false,
}: let
  exe =
    if buildServer
    then "xash"
    else "xash3d";
in
  stdenv.mkDerivation {
    pname = "xash3d-fwgs";
    version = "0-unstable-2026-04-18";

    src = fetchFromGitHub {
      owner = "FWGS";
      repo = "xash3d-fwgs";
      rev = "da4c4bb76a06de87b85de594ddd7008f0705c131";
      hash = "sha256-ve5rJHoxu69dC/H7nvTkeqcytAi5cPzFcD2VnjfJ200=";
      postCheckout = ''
        cd $out/3rdparty
        git submodule update --init --recursive \
          MultiEmulator extras/xash-extras gl-wes-v2 gl4es/gl4es \
          libbacktrace/libbacktrace library_suffix maintui mainui nanogl \
          vgui_support
      '';
    };

    nativeBuildInputs = [
      ensureNewerSourcesForZipFilesHook
      python3
      pkg-config
      wafHook
      makeWrapper
    ];

    buildInputs =
      lib.optionals (!buildServer) [
        freetype
        opusfile
        libopus
        libogg
        libvorbis
        bzip2
        SDL2
      ]
      ++ lib.optionals (!buildServer && stdenv.isLinux) [
        libx11
      ];

    dontAddPrefix = true;

    wafConfigureFlags =
      [
        "-T release"
      ]
      ++ lib.optionals buildServer [
        "-d"
      ]
      ++ lib.optionals (!buildServer) [
        "--sdl-use-pkgconfig"
      ]
      ++ lib.optionals stdenv.buildPlatform.is64bit ["-8"];

    wafInstallFlags = ["--destdir=${placeholder "out"}/lib"];

    postInstall =
      ''
        mkdir -p $out/bin
        mv $out/lib/${exe} $out/bin/${exe}-unwrapped
        makeWrapper $out/bin/${exe}-unwrapped $out/bin/${exe} \
          --set XASH3D_RODIR $out/lib \
          --run "export XASH3D_BASEDIR=\$HOME/.xash3d/" \
          --prefix ${
          if stdenv.hostPlatform.isDarwin
          then "DYLD_LIBRARY_PATH"
          else "LD_LIBRARY_PATH"
        } : "$out/lib"
      ''
      + lib.concatLines (lib.map (sdk: "cp -TR ${sdk}/${sdk.modDir} $out/lib/${sdk.modDir}") sdks);

    passthru.updateScript = nix-update-script {
      extraArgs = [
        "--version=branch"
        "--version-regex=(0-unstable-.*)"
      ];
    };

    meta = {
      homepage = "https://github.com/FWGS/xash3d-fwgs";
      description = "Xash3D FWGS engine";
      license = lib.licenses.gpl3Plus;
      platforms = lib.platforms.all;
      maintainers = with lib.maintainers; [r4v3n6101];
      mainProgram = exe;
    };
  }
