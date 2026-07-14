{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:
buildPythonPackage rec {
  pname = "factorio-rcon-py";
  version = "2.1.3";
  pyproject = true;

  src = fetchPypi {
    pname = "factorio_rcon_py";
    inherit version;
    hash = "sha256-hL/ELSrfzQFmC9QDZSxkU/a+K0dIF+IU51IG8CsVEsM=";
  };

  build-system = [setuptools];

  pythonImportsCheck = ["factorio_rcon"];

  meta = {
    description = "Simple factorio RCON client";
    homepage = "https://github.com/mark9064/factorio-rcon-py";
    license = lib.licenses.lgpl21Only;
  };
}
