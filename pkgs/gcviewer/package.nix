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
  version = "0.1.0-unstable-2025-04-29";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = "gcviewer";
    rev = "32cae0e9dfe2f37aa713280d5c7e311a3591215a";
    sha256 = "sha256-pk/rVKc0NJjwN76CdW4Z5z4Miv8HCTJQlpZ08q+QsBw=";
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
