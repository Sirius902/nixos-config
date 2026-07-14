{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
}:
buildPythonPackage rec {
  pname = "pymem";
  version = "1.14.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-KfbDK8rQAyiIr6ut+X0eTHdX+Ihz3k159/TB35uefvE=";
  };

  build-system = [poetry-core];

  meta = {
    description = "Python library for windows memory reading and writing";
    homepage = "https://github.com/srounet/Pymem";
    license = lib.licenses.mit;
  };
}
