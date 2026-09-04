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
  xxhash,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dusklight-cosmetics";
  version = "0-unstable-2026-09-03";

  src = fetchFromGitHub {
    owner = "TwilitRealm";
    repo = "dusklight-cosmetics";
    rev = "93971c38aa7286c59be7c3874a95e12d1a37036a";
    hash = "sha256-MerDtCz2LzSfcinfVpwkp2oB5LC9/yjDq3X0XyNtCP4=";
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

  ninjaFlags = ["cosmetics_package"];

  cmakeFlags =
    [
      (lib.cmakeBool "CMAKE_FIND_PACKAGE_TARGETS_GLOBAL" true)
      (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_XXHASH" "${xxhash.src}")
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

    install -Dm444 -t $out/lib/${finalAttrs.pname} mods/cosmetics.dusk

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
    homepage = "https://github.com/TwilitRealm/dusklight-cosmetics";
    description = "Cosmetic customization mod for Dusklight";
    maintainers = with lib.maintainers; [sirius902];
    platforms = ["x86_64-linux" "aarch64-darwin"];
    license = lib.licenses.unfree;
  };
})
