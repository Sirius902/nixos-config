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
  version = "3.0.1-unstable-2025-08-31";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = "gcfeeder";
    rev = "bab70a07ceb77ba490af83d571aece0b08f40683";
    sha256 = "sha256-ohzvAJ4vq7d9TNtYJyM+faJ3kWXzFTGL5OH/vB0g2WM=";
  };

  cargoBuildFlags = "-p gcfeederd --no-default-features";
  cargoHash = "sha256-UlaSfZPi5jyx3pasJreTbdYxsC7XM37GCADeMbb96cU=";

  # TODO(Sirius902) Remove once these tests pass.
  checkFlags = map (t: "--skip=${t}") [
    "layers::mm_vc::tests::inv_vc_main_stick_works"
    "layers::z64_gc::tests::inv_gc_main_stick_works"
  ];

  nativeBuildInputs =
    [
      copyDesktopItems
    ]
    ++ lib.optionals stdenv.isLinux [
      pkg-config
      autoPatchelfHook
    ];

  runtimeDependencies = lib.optionals stdenv.isLinux [
    libappindicator-gtk3
  ];

  buildInputs =
    lib.optionals stdenv.isLinux [
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
