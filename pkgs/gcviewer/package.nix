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
  version = "0.1.0-unstable-2025-08-31";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = "gcviewer";
    rev = "84b95d76b0b25bd64fee9af23c592889d9d97369";
    sha256 = "sha256-+Wji7ZIMjs9mZZ7d6Ub6OXpqCf7U5DyXgJkaog/ZqU4=";
  };

  cargoBuildFlags = "--no-default-features";
  cargoHash = "sha256-wyzY4TkobIgSMhkXJYjCUXQCCaTCcip7qaup8XxikMU=";

  nativeBuildInputs =
    [
      copyDesktopItems
    ]
    ++ lib.optionals stdenv.isLinux [
      pkg-config
      autoPatchelfHook
    ];

  runtimeDependencies = lib.optionals stdenv.isLinux [
    # TODO(Sirius902) What in the world is calling dlopen for `libgcc_s.so.1`??
    stdenv.cc.cc.lib
    libxkbcommon
    vulkan-loader
    wayland
  ];

  buildInputs =
    lib.optionals stdenv.isLinux [
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
