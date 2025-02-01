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
  version = "858d48e";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = pname;
    # TODO(Sirius902) Change to tag when release comes out.
    rev = version;
    sha256 = "sha256-QFwfh+CX/RS0TAc1cKyMxXNeBStvy1dsgPa8pXoh9qQ=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-KRQb8DkwmOX4pIWQo4nfTBfjLnRk9pkw2Z6QtVccvvA=";

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

  # FUTURE(Sirius902) Custom shader option that can be overriden?
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
    description = "GameCube input viewer for use with gcfeeder.";
    homepage = "https://github.com/Sirius902/gcviewer";
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "gcviewer";
  };
}
