{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  apple-sdk_15,
  darwinMinVersionHook,
  dusklight,
  fmt,
  xxhash,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dusklight-basic-cosmetics";

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

  cmakeDir = "../mods/basic_cosmetics_mod";

  ninjaFlags = ["basic_cosmetics_mod_package"];

  cmakeFlags =
    [
      (lib.cmakeBool "CMAKE_FIND_PACKAGE_TARGETS_GLOBAL" true)
      (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
      # xxHash keeps its CMake project in a subdirectory; in the game tree
      # aurora declares it with that SOURCE_SUBDIR first, but this mod's own
      # declaration is bare, so the path has to carry it instead.
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_XXHASH" "${xxhash.src}/cmake_unofficial")
      (lib.cmakeBool "XXHASH_BUILD_XXHSUM" false)
      (lib.cmakeBool "BUILD_SHARED_LIBS" false)
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      # A game-feature mod links against the game binary with -bundle_loader;
      # without this the SDK downloads a link stub over the network.
      (lib.cmakeFeature "DUSK_GAME_EXE" "${dusklight}/Applications/Dusklight.app/Contents/MacOS/Dusklight")
    ];

  installPhase = ''
    runHook preInstall

    install -Dm444 -t $out/lib/${finalAttrs.pname} mods/basic_cosmetics_mod.dusk

    runHook postInstall
  '';

  strictDeps = true;
  __structuredAttrs = true;

  meta = {
    homepage = "https://github.com/TwilitRealm/dusklight";
    description = "Cosmetic customization mod for Dusklight";
    maintainers = with lib.maintainers; [sirius902];
    platforms = ["x86_64-linux" "aarch64-darwin"];
    license = with lib.licenses; [unfree];
  };
})
