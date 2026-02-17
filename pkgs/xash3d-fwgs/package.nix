{
  lib,
  fetchFromGitHub,
  stdenv,
  ensureNewerSourcesForZipFilesHook,
  python3,
  pkg-config,
  wafHook,
  SDL2,
  libX11,
  freetype,
  opusfile,
  libopus,
  libogg,
  libvorbis,
  bzip2,
  xash-sdk,
  makeWrapper,
  nix-update-script,
  # Options
  sdks ? [xash-sdk],
}:
stdenv.mkDerivation {
  pname = "xash3d-fwgs";
  version = "0-unstable-2026-02-16";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "xash3d-fwgs";
    fetchSubmodules = true;
    rev = "2f8a0510b873d82c30218c4455747380c4f7ee4e";
    hash = "sha256-CKqwyINfvDL20Vk0fYmhnEbPkJTO8tFqbGqBk09dqOk=";
  };

  nativeBuildInputs = [
    ensureNewerSourcesForZipFilesHook
    python3
    pkg-config
    wafHook
    makeWrapper
  ];

  buildInputs =
    [
      freetype
      opusfile
      libopus
      libogg
      libvorbis
      bzip2
      SDL2
    ]
    ++ lib.optionals stdenv.isLinux [
      libX11
    ];

  dontAddPrefix = true;

  wafConfigureFlags =
    [
      "-T release"
      "--sdl-use-pkgconfig"
    ]
    ++ lib.optionals stdenv.buildPlatform.is64bit ["-8"];

  CFLAGS = "-I${SDL2.dev}/include/SDL2";

  preInstall = ''
    mkdir -p $out/lib
  '';

  wafInstallFlags = ["--destdir=${placeholder "out"}/lib"];

  postInstall =
    ''
      mkdir -p $out/opt
      mv $out/lib/valve $out/opt

      mkdir -p $out/bin
      mv $out/lib/xash3d $out/bin/xash3d-unwrapped
      makeWrapper $out/bin/xash3d-unwrapped $out/bin/xash3d \
        --set XASH3D_RODIR $out/opt \
        --run "export XASH3D_BASEDIR=\$HOME/.xash3d/" \
        --prefix ${
        if stdenv.hostPlatform.isDarwin
        then "DYLD_LIBRARY_PATH"
        else "LD_LIBRARY_PATH"
      } : "$out/lib"
    ''
    + lib.concatLines (lib.map (sdk: "cp -TR ${sdk}/${sdk.modDir} $out/opt/${sdk.modDir}") sdks);

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
    mainProgram = "xash3d";
  };
}
