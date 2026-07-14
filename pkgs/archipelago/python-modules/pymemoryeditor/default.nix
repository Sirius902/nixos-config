{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
}:
buildPythonPackage rec {
  pname = "pymemoryeditor";
  version = "2.0.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-tIpHxeFVouVO1esIbVP4gOIqYPq2qS0a7pRjZwzp46U=";
  };

  build-system = [hatchling];

  pythonImportsCheck = ["PyMemoryEditor"];

  meta = {
    description = "Multi-platform library to read and write process memory";
    homepage = "https://github.com/JeanExtreme002/PyMemoryEditor";
    license = lib.licenses.mit;
  };
}
