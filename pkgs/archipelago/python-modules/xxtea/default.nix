{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:
buildPythonPackage rec {
  pname = "xxtea";
  version = "3.7.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-KLofMmRrDT60POd04qgG9TFfE9qatYcHXv0docNwoFI=";
  };

  build-system = [setuptools];

  pythonImportsCheck = ["xxtea"];

  meta = {
    description = "XXTEA implemented as a Python extension module";
    homepage = "https://github.com/ifduyue/xxtea";
    license = lib.licenses.bsd2;
  };
}
