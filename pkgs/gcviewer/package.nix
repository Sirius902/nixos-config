{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  autoPatchelfHook,
  libGL,
  libxkbcommon,
  vulkan-loader,
  wayland,
  xorg,
  pkg-config,
  libudev-zero,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gcviewer";
  version = "0.1.0-unstable-2025-12-30";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = "gcviewer";
    rev = "eb1b0e9ad499dbcc2cb90b4a2c133be689c8e2c6";
    sha256 = "sha256-U8cyKJ8bWGwFaDowLsI4yhvThvstOcaWkvk2KAIT12A=";
  };

  cargoBuildFlags = "--no-default-features";
  cargoHash = "sha256-ubrVF6WQg1brQoYJxY1sgNnWxwGr+FadO+C+EPJbeRU=";

  nativeBuildInputs =
    [
      copyDesktopItems
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      pkg-config
      autoPatchelfHook
    ];

  runtimeDependencies = lib.optionals stdenv.hostPlatform.isLinux [
    # TODO(Sirius902) What in the world is calling dlopen for `libgcc_s.so.1`??
    stdenv.cc.cc.lib
    libxkbcommon
    vulkan-loader
    wayland
  ];

  buildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [
      libGL
      xorg.libX11
      xorg.libXcursor
      xorg.libxcb
      xorg.libXi
      libudev-zero
    ]
    ++ finalAttrs.runtimeDependencies;

  postInstall = ''
    install -Dm644 resource/icon.png $out/share/pixmaps/gcviewer.png
  '';

  env.GCVIEWER_VERSION = "v${finalAttrs.version}";

  desktopItems = [
    (makeDesktopItem {
      name = "gcviewer";
      icon = "gcviewer";
      exec = "gcviewer %U";
      comment = finalAttrs.meta.description;
      desktopName = "gcviewer";
      categories = ["Utility"];
    })
  ];

  passthru.updateScript = nix-update-script {extraArgs = ["--version=branch=serial"];};

  meta = with lib; {
    description = "A customizable input viewer.";
    homepage = "https://github.com/Sirius902/gcviewer";
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "gcviewer";
  };
})
