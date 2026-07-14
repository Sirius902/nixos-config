{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:
buildPythonPackage rec {
  pname = "websockets";
  version = "13.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "python-websockets";
    repo = "websockets";
    tag = version;
    hash = "sha256-Y0HDZw+H7l8+ywLLzFk66GNDCI0uWOZYypG86ozLo7c=";
  };

  build-system = [setuptools];

  pythonImportsCheck = ["websockets"];

  meta = {
    description = "Library for building WebSocket servers and clients in Python";
    homepage = "https://github.com/python-websockets/websockets";
    license = lib.licenses.bsd3;
  };
}
