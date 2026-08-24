{
  applyPatches,
  bzip2,
  callPackage,
  cmake,
  fetchFromGitHub,
  glew,
  lib,
  libGL,
  libpulseaudio,
  libx11,
  ninja,
  nix-update-script,
  pkg-config,
  SDL2,
  zlib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: let
  # Upstream's submodules use git@github.com: URLs, so fetchSubmodules can't
  # clone them. These mirror the two submodule gitlinks and the FetchContent
  # GIT_TAG in OTRizer/CMakeLists.txt, and have to be re-pinned by hand when
  # src moves.
  zeldaOtrizer = fetchFromGitHub {
    owner = "leggettc18";
    repo = "ZeldaOTRizer";
    rev = "efd2b3dc943018bb0b73d3d70e1a321918d14f76";
    hash = "sha256-rZLtcEmcp2t4tMBnqWMitMKCSR5f2y0TI0b1tOz1fuM=";
  };

  otrizer = fetchFromGitHub {
    owner = "leggettc18";
    repo = "OTRizer";
    rev = "2eb0979e91ae79af557b65908146baf09e7fc747";
    hash = "sha256-MU0cAeV7sZfxUo/1N8Om/h22DD9SORZvqAzRGZO8a+I=";
  };

  libultraship = applyPatches {
    src = fetchFromGitHub {
      owner = "Kenix3";
      repo = "libultraship";
      rev = "823d98f3dd5f7f82fb70a31c9ac1fc01ea584f5f";
      hash = "sha256-AF+2pRe+wWC1KzLRoevbS7Cshap5emx9Hektdbjp3TY=";
    };
    patches = [./libultraship-source-date-epoch.patch];
  };
in {
  pname = "sequence-otrizer";
  version = "0.4";

  src = fetchFromGitHub {
    owner = "leggettc18";
    repo = "SequenceOTRizer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GBm5PODUGwWf8BFu72omtIAPOY/HUeSkZmSXu6ZDxQ0=";
  };

  patches = [./sort-sequence-traversal.patch];

  # GitHub tarballs ship submodule paths as empty directories, so -T is needed
  # to fill them in rather than nest a copy inside them.
  postPatch = ''
    cp -rT --no-preserve=mode ${zeldaOtrizer} ZeldaOTRizer
    cp -rT --no-preserve=mode ${otrizer} ZeldaOTRizer/OTRizer
  '';

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs =
    [
      SDL2
      bzip2
      glew
      zlib
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      libGL
      libpulseaudio
      libx11
    ];

  cmakeFlags = [
    (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_LIBULTRASHIP" "${libultraship}")
    # libultraship's vendored nlohmann-json asks for cmake 3.1, below the 3.5
    # floor cmake 4 enforces.
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    # libultraship predates GCC 13 dropping the transitive <cstdint> include.
    # JSON_HAS_THREE_WAY_COMPARISON=0 holds the vendored nlohmann-json 3.11.2 to
    # its pre-C++20 comparison operators, the API this code was written against;
    # the rewritten C++20 ones can't compare a std::string against a json until
    # 3.11.3. Both go on CMAKE_CXX_FLAGS rather than NIX_CFLAGS_COMPILE so the
    # vendored C sources aren't handed a C++ header.
    (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-include cstdint -DJSON_HAS_THREE_WAY_COMPARISON=0")
  ];

  strictDeps = true;
  __structuredAttrs = true;
  enableParallelBuilding = true;

  # Upstream installs to `RUNTIME DESTINATION .`, which would litter the top
  # level of $out.
  installPhase = ''
    runHook preInstall

    install -Dm755 SequenceOTRizer -t $out/bin

    install -Dm644 -t $out/share/licenses/sequence-otrizer ../LICENSE
    install -Dm644 -t $out/share/licenses/sequence-otrizer/ZeldaOTRizer ../ZeldaOTRizer/LICENSE
    install -Dm644 -t $out/share/licenses/sequence-otrizer/OTRizer ../ZeldaOTRizer/OTRizer/LICENSE
    install -Dm644 -t $out/share/licenses/sequence-otrizer/libultraship ${libultraship}/LICENSE

    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        # Upstream also carries `test-tag` and `test-tag-pack`.
        "--version-regex=v(.*)"
      ];
    };

    # Checks a pack this built against the sequences it was built from. Lives
    # here because every pack needs it and none of them own it.
    mkOtrTest = callPackage ./otr-test.nix {};
  };

  meta = {
    homepage = "https://github.com/leggettc18/SequenceOTRizer";
    description = "Packs custom Ocarina of Time sequences into an OTR archive";
    license = lib.licenses.mit;
    mainProgram = "SequenceOTRizer";
    maintainers = with lib.maintainers; [sirius902];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
