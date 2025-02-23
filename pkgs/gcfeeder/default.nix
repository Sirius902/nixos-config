{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
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
}:
rustPlatform.buildRustPackage rec {
  pname = "gcfeeder";
  version = "d73b0ca";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = pname;
    # TODO(Sirius902) Change to tag when release comes out.
    rev = version;
    sha256 = "sha256-jdkHNgepqXlu0JPFKxL7V1LgvFgeUG+3SlQ3cRixbWM=";
  };

  cargoPatches = [./libusb1-sys-darwin-reproducible.patch];

  useFetchCargoVendor = true;
  cargoHash = "sha256-/wb2X7FWWkNxUWt2lTN8chDDNYf4qUO2jJdQoAZNPvk=";

  nativeBuildInputs =
    [
      copyDesktopItems
      makeWrapper
    ]
    ++ lib.optionals stdenv.isLinux [
      pkg-config
    ];

  buildInputs = lib.optionals stdenv.isLinux [
    libGL
    libxkbcommon
    vulkan-loader
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.libxcb
    xorg.libXi
    gdk-pixbuf
    glib
    gtk3
    libappindicator-gtk3
    xdotool
    zlib
  ];

  postInstall = ''
    wrapProgram $out/bin/gcfeeder \
      --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}

    mkdir -p $out/lib/udev/rules.d
    cp rules/50-gcfeeder.rules $out/lib/udev/rules.d/

    install -Dm644 crates/gcfeeder/resource/icon.png $out/share/pixmaps/gcfeeder.png
  '';

  GCFEEDER_VERSION = "v3.0.1-${version}";

  desktopItems = [
    (makeDesktopItem {
      name = "gcfeeder";
      icon = "gcfeeder";
      exec = "gcfeeder %U";
      comment = meta.description;
      desktopName = "gcfeeder";
      categories = ["Utility"];
    })
  ];

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
}
