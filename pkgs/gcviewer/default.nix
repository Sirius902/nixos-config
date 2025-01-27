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
  version = "c3d36e6";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = pname;
    rev = version;
    sha256 = "sha256-ATbUBmxjniRIIpNuEAFC7kp1O2Jnv7xnaMb2T8t2+uk=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-k9lHnJnjHn/5Obo51I5ErpOLy0pGXCNmye87TsTe3Po=";

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

  VERSION = "g${version}";

  desktopItems = [
    (makeDesktopItem {
      name = "gcviewer";
      icon = "gcviewer";
      exec = "gcviewer %U";
      desktopName = "gcviewer";
      categories = ["Utility"];
    })
  ];

  meta = with lib; {
    homepage = "https://github.com/Sirius902/gcviewer";
    platforms = platforms.linux;
    mainProgram = "gcviewer";
  };
}
