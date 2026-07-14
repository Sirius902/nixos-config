{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:
buildPythonPackage rec {
  pname = "pyevermizer";
  version = "0.50.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-zVbMom7ZZ1eQFU3XBAKtKKOB/DyQMb0C65sdrYwxc5g=";
  };

  build-system = [setuptools];

  pythonImportsCheck = ["pyevermizer"];

  meta = {
    description = "Python wrapper for Evermizer, the Secret of Evermore randomizer";
    homepage = "https://github.com/black-sliver/pyevermizer";
    license = lib.licenses.lgpl3Only;
  };
}
