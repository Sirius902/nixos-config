{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
  charset-normalizer,
}:
buildPythonPackage rec {
  pname = "pyshortcuts";
  version = "1.9.7";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-vy8o1efl5dglNm/2MlG+VRiUbx4xpnK10X/BmQm3ifs=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [charset-normalizer];

  pythonImportsCheck = ["pyshortcuts"];

  meta = {
    description = "Create desktop and Start Menu shortcuts for python scripts";
    homepage = "https://github.com/newville/pyshortcuts";
    license = lib.licenses.mit;
  };
}
