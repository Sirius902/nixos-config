{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  fetchFromGitHub,
  apple-sdk_15,
  darwinMinVersionHook,
  dusklight,
  fmt,
  nix-update-script,
}: let
  base64pp-src = fetchFromGitHub {
    owner = "matheusgomes28";
    repo = "base64pp";
    rev = "v0.2.0-rc0";
    hash = "sha256-DYdnjbdZmQFOizg2SwAu35kWA0F72tE6ywe00azlqxk=";
  };

  battery-embed-src = fetchFromGitHub {
    owner = "batterycenter";
    repo = "embed";
    rev = "fdbae3f";
    hash = "sha256-yCLADGd8VITzIWr3aEt+jrzUDAKTk3YljNOuToK1zio=";
  };

  yaml-cpp-src = fetchFromGitHub {
    owner = "jbeder";
    repo = "yaml-cpp";
    rev = "yaml-cpp-0.9.0";
    hash = "sha256-+FOsPQY44h1g9tEw3O281LkiYKXdW2jnFKw+oTRkhGw=";
  };
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "dusklight-randomizer";
    version = "0-unstable-2026-09-05";

    src = fetchFromGitHub {
      owner = "TwilitRealm";
      repo = "dusklight-randomizer";
      rev = "bf1fd8db325e762910cce19c34501e951c70cf39";
      hash = "sha256-wdni5qkrC1Th0xS9QxfrhVzwEFLwm3j5XRgnkYOG3V4=";
    };

    nativeBuildInputs =
      [
        cmake
        ninja
        pkg-config
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        (darwinMinVersionHook "15.0")
      ];

    buildInputs =
      [
        fmt
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        apple-sdk_15
      ];

    # base64pp's CMakeLists generates its export header into its own source tree.
    preConfigure = ''
      cp -r --no-preserve=mode ${base64pp-src} base64pp-src
      cmakeFlags+=("-DFETCHCONTENT_SOURCE_DIR_BASE64PP=$PWD/base64pp-src")
    '';

    # randomizer_generator_tests computes RANDO_LOGIC_TESTS_PATH from
    # CMAKE_SOURCE_DIR, which out of tree is the mod directory rather than the
    # game root.
    ninjaFlags = ["randomizer_package"];

    cmakeFlags =
      [
        (lib.cmakeBool "CMAKE_FIND_PACKAGE_TARGETS_GLOBAL" true)
        (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_BATTERY-EMBED" "${battery-embed-src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_YAML-CPP" "${yaml-cpp-src}")
        (lib.cmakeFeature "DUSKLIGHT_DIR" "${dusklight.src}")
        (lib.cmakeBool "BUILD_SHARED_LIBS" false)
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        # A game-feature mod links against the game binary with -bundle_loader;
        # without this the SDK downloads a link stub over the network.
        (lib.cmakeFeature "DUSK_GAME_EXE" "${dusklight}/Applications/Dusklight.app/Contents/MacOS/Dusklight")
      ];

    installPhase = ''
      runHook preInstall

      install -Dm444 -t $out/lib/${finalAttrs.pname} mods/randomizer.dusk

      runHook postInstall
    '';

    strictDeps = true;
    __structuredAttrs = true;

    passthru.updateScript = nix-update-script {
      extraArgs = [
        "--version=branch"
        "--version-regex=(0-unstable-.*)"
      ];
    };

    meta = {
      homepage = "https://github.com/TwilitRealm/dusklight-randomizer";
      description = "Randomizer mod for Dusklight";
      maintainers = with lib.maintainers; [sirius902];
      platforms = ["x86_64-linux" "aarch64-darwin"];
      license = lib.licenses.unfree;
    };
  })
