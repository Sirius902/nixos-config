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
  pname = "gcviewer";
  version = "c0f58fdb";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = pname;
    # TODO(Sirius902) Change to tag when release comes out.
    rev = version;
    sha256 = "sha256-9GdXJ2A4K/PRq/HqwZnrgaT9b2tZNJ0OdRn/SfHrEHk=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-8tCsuvabpLADU0N5BCNFd3hxwqy1+Szi5Xq93S48W/o=";

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
    wrapProgram $out/bin/gcviewer \
      --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}

    install -Dm644 resource/icon.png $out/share/pixmaps/gcviewer.png
  '';

  GCVIEWER_VERSION = "v0.1.0-${version}";

  desktopItems = [
    (makeDesktopItem {
      name = "gcviewer";
      icon = "gcviewer";
      exec = "gcviewer %U";
      comment = meta.description;
      desktopName = "gcviewer";
      categories = ["Utility"];
    })
  ];

  meta = with lib; {
    description = "A customizable input viewer.";
    homepage = "https://github.com/Sirius902/gcviewer";
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "gcviewer";
  };
}
