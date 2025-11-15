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
  version = "0.1.0-unstable-2025-11-15";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = "gcviewer";
    rev = "71acd781ac5cbefb3513174593ef5557e1d18779";
    sha256 = "sha256-qY/WPyFTnlltDMe+s1WDdN3tpTSiXRD3KGwOCL12Ib4=";
  };

  cargoBuildFlags = "--no-default-features";
  cargoHash = "sha256-HNbHpfQ7GcP4oIU3Hj8PEJVINEAWl2zoGRLoP19pMRs=";

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
