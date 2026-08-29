{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pkg-config,
  cython_0,
  setuptools,
  docutils,
  filetype,
  gst_all_1,
  kivy-garden,
  libGL,
  libx11,
  mtdev,
  pygments,
  requests,
  SDL2,
  SDL2_image,
  SDL2_mixer,
  SDL2_ttf,
}:
# nixpkgs ships a Kivy 3 master snapshot under a `2.3.1-unstable-*` label, which
# renamed `kivy.core.audio` and moved to SDL3. Archipelago pins `kivy==2.3.1` and
# imports the old name, so hold the release here.
buildPythonPackage rec {
  pname = "kivy";
  version = "2.3.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kivy";
    repo = "kivy";
    tag = version;
    hash = "sha256-q8BoF/pUTW2GMKBhNsqWDBto5+nASanWifS9AcNRc8Q=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "setuptools~=69.2.0" "setuptools" \
      --replace-fail "wheel~=0.44.0" "wheel" \
      --replace-fail "cython>=0.29.1,<=3.0.11" "cython" \
      --replace-fail "packaging~=24.0" packaging

    substituteInPlace kivy/lib/mtdev.py \
      --replace-fail "LoadLibrary('libmtdev.so.1')" \
        "LoadLibrary('${lib.getLib mtdev}/lib/libmtdev.so.1')"
  '';

  build-system = [
    setuptools
    cython_0
  ];

  nativeBuildInputs = [pkg-config];

  buildInputs =
    [
      SDL2
      SDL2_image
      SDL2_mixer
      SDL2_ttf
      libGL
      libx11
      mtdev
    ]
    ++ (with gst_all_1; [
      gstreamer
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
    ]);

  dependencies = [
    docutils
    filetype
    kivy-garden
    pygments
    requests
  ];

  env = {
    KIVY_NO_CONFIG = 1;
    KIVY_NO_ARGS = 1;
    KIVY_NO_FILELOG = 1;
    # distutils compiles C++ with $CC (nixpkgs issue #26709).
    NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types";
  };

  # Kivy imports itself before it is fully installed.
  doCheck = false;

  pythonImportsCheck = ["kivy"];

  meta = {
    description = "Library for rapid development of hardware-accelerated multitouch applications";
    homepage = "https://github.com/kivy/kivy";
    license = lib.licenses.mit;
  };
}
