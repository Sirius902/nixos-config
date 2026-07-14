{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
  setuptools-cmake-helper,
  cython,
  cmake,
}:
buildPythonPackage rec {
  pname = "dolphin-memory-engine";
  version = "1.3.1";
  pyproject = true;

  src = fetchPypi {
    pname = "dolphin_memory_engine";
    inherit version;
    hash = "sha256-HCbjLMTVIQ+l/JGQ7vk8iNPgJiDKh6Ir+9h6a8YuK9s=";
  };

  build-system = [
    setuptools
    setuptools-scm
    setuptools-cmake-helper
    cython
  ];

  nativeBuildInputs = [cmake];
  dontUseCmakeConfigure = true;

  pythonImportsCheck = ["dolphin_memory_engine"];

  meta = {
    description = "Python library to read and write the memory of an emulated game in Dolphin";
    homepage = "https://github.com/henriquegemignani/py-dolphin-memory-engine";
    license = lib.licenses.mit;
  };
}
