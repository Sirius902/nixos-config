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
  pkg-config,
  libudev-zero,
}:
rustPlatform.buildRustPackage rec {
  pname = "gcviewer";
  version = "44865ac";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = pname;
    # TODO(Sirius902) Change to tag when release comes out.
    rev = version;
    sha256 = "sha256-rOPNnb2wR1/SXMTV/QHPqVeE5gwcPZTvUeGpOUD0+q4=";
  };

  cargoBuildFlags = "--no-default-features";

  cargoHash = "sha256-eTr7hLvO4mH9/sm5akl0UJUmky8adEdelQqF5Edlnvo=";

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
    pkg-config
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
    libudev-zero
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
