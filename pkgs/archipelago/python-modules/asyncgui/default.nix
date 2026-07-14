{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
}:
buildPythonPackage rec {
  pname = "asyncgui";
  version = "0.6.3";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Bd5JwiIRKNNTDwEN+YSR81Uxg+yJCdIFoMAlC+5dbgw=";
  };

  build-system = [poetry-core];

  pythonImportsCheck = ["asyncgui"];

  meta = {
    description = "Async library that focuses on fast reaction";
    homepage = "https://github.com/asyncgui/asyncgui";
    license = lib.licenses.mit;
  };
}
