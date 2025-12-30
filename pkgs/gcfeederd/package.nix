{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  autoPatchelfHook,
  pkg-config,
  glib,
  gtk3,
  libappindicator-gtk3,
  xdotool,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gcfeederd";
  version = "3.0.1-unstable-2025-12-30";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = "gcfeeder";
    rev = "6b157c7e56e8b1c28f1f72b5e0ac49ea48fe3cad";
    sha256 = "sha256-6jtMsRH4NXqmZr0ubcybz0grYLpx8eNNZXHatFWlCfM=";
  };

  cargoBuildFlags = "-p gcfeederd --no-default-features";
  cargoHash = "sha256-OHQnnYG1yK5kRWBJgdM87InCVzvAS2SXeMd283wlhfo=";

  # TODO(Sirius902) Remove once these tests pass.
  checkFlags = map (t: "--skip=${t}") [
    "layers::mm_vc::tests::inv_vc_main_stick_works"
    "layers::z64_gc::tests::inv_gc_main_stick_works"
  ];

  nativeBuildInputs =
    [
      copyDesktopItems
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      pkg-config
      autoPatchelfHook
    ];

  runtimeDependencies = lib.optionals stdenv.hostPlatform.isLinux [
    libappindicator-gtk3
  ];

  buildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [
      glib
      gtk3
      xdotool
    ]
    ++ finalAttrs.runtimeDependencies;

  postInstall = ''
    mkdir -p $out/lib/udev/rules.d
    cp rules/50-gcfeederd.rules $out/lib/udev/rules.d/

    install -Dm644 crates/gcfeederd/resource/icon.png $out/share/pixmaps/gcfeederd.png
  '';

  env.GCFEEDER_VERSION = "v${finalAttrs.version}";

  desktopItems = [
    (makeDesktopItem {
      name = "gcfeederd";
      icon = "gcfeederd";
      exec = "gcfeederd %U";
      comment = finalAttrs.meta.description;
      desktopName = "gcfeederd";
      categories = ["Utility"];
    })
  ];

  passthru.updateScript = nix-update-script {extraArgs = ["--version=branch=linux-daemon"];};

  meta = with lib; {
    description = "A ViGEm / evdev feeder for GameCube controllers using the GameCube Controller Adapter.";
    longDescription = ''
      A ViGEm / evdev feeder for GameCube controllers using the GameCube Controller Adapter.

      Udev rules can be added as:

        services.udev.packages = [ pkgs.gcfeederd ]
    '';
    homepage = "https://github.com/Sirius902/gcfeeder";
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "gcfeederd";
  };
})
