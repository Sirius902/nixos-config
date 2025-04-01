{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  pkg-config,
  glib,
  gtk3,
  libappindicator-gtk3,
  xdotool,
}:
rustPlatform.buildRustPackage rec {
  pname = "gcfeederd";
  version = "1025624";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = "gcfeeder";
    # TODO(Sirius902) Change to tag when release comes out.
    rev = version;
    sha256 = "sha256-S8TavzraYE9uBMfmeu1WNDlcFRmkEWk+j47w6vS79lE=";
  };

  cargoBuildFlags = "-p gcfeederd";
  # TODO(Sirius902) Enable this once tests pass.
  doCheck = false;

  useFetchCargoVendor = true;
  cargoHash = "sha256-75sHt6ITKiEDN2ebCyRwytQT+IpThIL6W0kBdBHk6Vw=";

  nativeBuildInputs =
    [
      copyDesktopItems
      makeWrapper
    ]
    ++ lib.optionals stdenv.isLinux [
      pkg-config
    ];

  buildInputs = lib.optionals stdenv.isLinux [
    glib
    gtk3
    libappindicator-gtk3
    xdotool
  ];

  postInstall = ''
    wrapProgram $out/bin/gcfeederd \
      --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}

    mkdir -p $out/lib/udev/rules.d
    cp rules/50-gcfeederd.rules $out/lib/udev/rules.d/

    install -Dm644 crates/gcfeederd/resource/icon.png $out/share/pixmaps/gcfeederd.png
  '';

  # TODO(Sirius902) Do this?
  # GCFEEDER_VERSION = "v3.0.1-${version}";

  desktopItems = [
    (makeDesktopItem {
      name = "gcfeederd";
      icon = "gcfeederd";
      exec = "gcfeederd %U";
      comment = meta.description;
      desktopName = "gcfeederd";
      categories = ["Utility"];
    })
  ];

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
}
