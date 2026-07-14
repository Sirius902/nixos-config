{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
  asyncgui,
}:
buildPythonPackage rec {
  pname = "asynckivy";
  version = "0.6.4";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-WMNIdqJCJGTznfEgtlnIsi4ESFLdf/lMW5y52thOkCs=";
  };

  build-system = [poetry-core];

  dependencies = [asyncgui];

  meta = {
    description = "Async library for Kivy";
    homepage = "https://github.com/asyncgui/asynckivy";
    license = lib.licenses.mit;
  };
}
