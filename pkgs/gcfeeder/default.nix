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
  version = "81b1ed9";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = pname;
    rev = version;
    sha256 = "sha256-Ys4sHSfLt6mJ5c+JL/CdGUdyxeo45tZlWDdV/PjOwec=";
  };

  cargoHash = "sha256-v95H0XojcQLJnSM40TFEm6lh37ss7nukJy6GK+1VjZM=";

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];

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

    install -Dm644 crates/gcfeeder/resource/icon.png $out/share/pixmaps/gcfeeder.png
  '';

  VERSION = "g${version}";

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
    homepage = "https://github.com/Sirius902/gcfeeder";
    platforms = platforms.linux;
    mainProgram = "gcfeeder";
  };
}
