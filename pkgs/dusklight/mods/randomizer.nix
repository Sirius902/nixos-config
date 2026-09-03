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

    # A mod binds to the game ABI of the revision it was built against.
    inherit (dusklight) src version;

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

    cmakeDir = "../mods/randomizer";

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

    meta = {
      homepage = "https://github.com/TwilitRealm/dusklight";
      description = "Randomizer mod for Dusklight";
      maintainers = with lib.maintainers; [sirius902];
      platforms = ["x86_64-linux" "aarch64-darwin"];
      license = with lib.licenses; [unfree];
    };
  })
