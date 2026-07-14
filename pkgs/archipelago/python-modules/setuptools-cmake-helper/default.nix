{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
}:
buildPythonPackage rec {
  pname = "setuptools-cmake-helper";
  version = "0.2.2";
  pyproject = true;

  src = fetchPypi {
    pname = "setuptools_cmake_helper";
    inherit version;
    hash = "sha256-cndQC0LMvKo00slGoTOgpV6/Vvcqm/Bs78xokkG3a6c=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [setuptools];

  pythonImportsCheck = ["setuptools_cmake_helper"];

  meta = {
    description = "Setuptools helper for building CMake extensions";
    homepage = "https://github.com/henriquegemignani/setuptools-cmake-helper";
    license = lib.licenses.asl20;
  };
}
