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
  version = "707ecc4";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = pname;
    # TODO(Sirius902) Change to tag when release comes out.
    rev = version;
    sha256 = "sha256-qQ+12ADIAhWjUC63GVcALmFlMm5Qd29fvK86F62dmB0=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-Ql6wjU7L8genCqqisv+3B/XsG8e3UibdelN2oOASKP8=";

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
