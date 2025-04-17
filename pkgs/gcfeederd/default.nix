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
  version = "a626419";

  src = fetchFromGitHub {
    owner = "Sirius902";
    repo = "gcfeeder";
    # TODO(Sirius902) Change to tag when release comes out.
    rev = version;
    sha256 = "sha256-xNkFl+V848P5DjbL561P9cwOEPvqXkiDOUdE1rk4MRc=";
  };

  cargoBuildFlags = "-p gcfeederd --no-default-features";
  # TODO(Sirius902) Enable this once tests pass.
  doCheck = false;

  useFetchCargoVendor = true;
  cargoHash = "sha256-0HRaBayGLTWcQqAAQWFsh56zfxw2ZNLahgfgcofuWCQ=";

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
