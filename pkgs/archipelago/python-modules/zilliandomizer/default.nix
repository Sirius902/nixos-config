{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  setuptools-scm,
  typing-extensions,
}:
buildPythonPackage rec {
  pname = "zilliandomizer";
  version = "0.9.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "beauxq";
    repo = "zilliandomizer";
    rev = "96d9a20f8278cee64bb4db859fbd874e0f332d36";
    hash = "sha256-8QkjVl7kNjpww64bs8UpSdpMhpdtYGyILYjxwMgZWoc=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [typing-extensions];

  env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

  pythonImportsCheck = ["zilliandomizer"];

  meta = {
    description = "Zillion randomizer";
    homepage = "https://github.com/beauxq/zilliandomizer";
    license = lib.licenses.agpl3Only;
  };
}
