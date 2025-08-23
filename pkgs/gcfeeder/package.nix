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
  gdk-pixbuf,
  glib,
  gtk3,
  libappindicator-gtk3,
  xdotool,
  zlib,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gcfeeder";
  version = "3.0.1-unstable-2025-02-22";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = "gcfeeder";
    rev = "d73b0caefb61ad91de0753631e1888bb8982cea1";
    sha256 = "sha256-jdkHNgepqXlu0JPFKxL7V1LgvFgeUG+3SlQ3cRixbWM=";
  };

  cargoPatches = [./libusb1-sys-darwin-reproducible.patch];
  cargoHash = "sha256-/wb2X7FWWkNxUWt2lTN8chDDNYf4qUO2jJdQoAZNPvk=";

  nativeBuildInputs =
    [
      copyDesktopItems
    ]
    ++ lib.optionals stdenv.isLinux [
      pkg-config
      autoPatchelfHook
    ];

  runtimeDependencies = lib.optionals stdenv.isLinux [
    libxkbcommon
    vulkan-loader
    wayland
    gdk-pixbuf
    glib
    gtk3
    libappindicator-gtk3
  ];

  buildInputs =
    lib.optionals stdenv.isLinux [
      libGL
      xorg.libX11
      xorg.libXcursor
      xorg.libxcb
      xorg.libXi
      xdotool
      zlib
    ]
    ++ finalAttrs.runtimeDependencies;

  postInstall = ''
    mkdir -p $out/lib/udev/rules.d
    cp rules/50-gcfeeder.rules $out/lib/udev/rules.d/

    install -Dm644 crates/gcfeeder/resource/icon.png $out/share/pixmaps/gcfeeder.png
  '';

  env.GCFEEDER_VERSION = "v${finalAttrs.version}";

  desktopItems = [
    (makeDesktopItem {
      name = "gcfeeder";
      icon = "gcfeeder";
      exec = "gcfeeder %U";
      comment = finalAttrs.meta.description;
      desktopName = "gcfeeder";
      categories = ["Utility"];
    })
  ];

  passthru.updateScript = nix-update-script {extraArgs = ["--version=branch=linux"];};

  meta = with lib; {
    description = "A ViGEm / evdev feeder for GameCube controllers using the GameCube Controller Adapter.";
    longDescription = ''
      A ViGEm / evdev feeder for GameCube controllers using the GameCube Controller Adapter.

      Udev rules can be added as:

        services.udev.packages = [ pkgs.gcfeeder ]
    '';
    homepage = "https://github.com/Sirius902/gcfeeder";
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "gcfeeder";
  };
})
