{
  lib,
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
}:
rustPlatform.buildRustPackage rec {
  pname = "gcfeeder";
  version = "a0d774f";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = pname;
    # TODO(Sirius902) Change to tag when release comes out.
    rev = version;
    sha256 = "sha256-izXhteD4aFfeoVG5GE63GagIFf57ZoXfQky8j32bSeI=";
  };

  cargoPatches = [./libusb1-sys-darwin-reproducible.patch];

  useFetchCargoVendor = true;
  cargoHash = "sha256-Fwo2eJX9XzoboxmF05ZqxrG5W5+M15uAfaejacDup/4=";

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];

  # TODO(Sirius902) Figure out why tf this is working without libusb1 and pkg-config.
  buildInputs = [
    libGL
    libxkbcommon
    vulkan-loader
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.libxcb
    xorg.libXi
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
