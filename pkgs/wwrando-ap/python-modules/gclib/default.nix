{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  numpy,
  pillow,
}:
buildPythonPackage {
  pname = "gclib";
  version = "1.0.0-unstable-2025-04-04";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "LagoLunatic";
    repo = "gclib";
    rev = "3072ee11fd2293fe0beb137616e91311e384176f";
    hash = "sha256-1XSiaVYU8dlprur4VfaCW4gaIVMNfC7JdyYbvxZMEDQ=";
  };

  postPatch = ''
    substituteInPlace gclib/bunfoe.py \
      --replace-fail "import dataclasses" "import dataclasses; from reprlib import recursive_repr" \
      --replace-fail "@dataclasses._recursive_repr" "@recursive_repr()"
  '';

  build-system = [setuptools];

  dependencies = [
    numpy
    pillow
  ];

  pythonImportsCheck = ["gclib"];

  meta = {
    description = "Library for reading and writing GameCube file formats";
    homepage = "https://github.com/LagoLunatic/gclib";
    license = lib.licenses.mit;
  };
}
