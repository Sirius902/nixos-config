{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:
buildPythonPackage rec {
  pname = "maseya-z3pr";
  version = "1.0.0rc1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-wCj9syUrSuLIbwfsyZY2n+Oar+s7oxQBG/Y3Ilf4Z8U=";
  };

  build-system = [setuptools];

  pythonImportsCheck = ["maseya.z3pr"];

  meta = {
    description = "Randomize palette data of The Legend of Zelda: A Link to the Past";
    homepage = "https://github.com/maseya/z3pr-py";
    license = lib.licenses.lgpl3Plus;
  };
}
