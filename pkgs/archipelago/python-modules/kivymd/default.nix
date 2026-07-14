{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  asynckivy,
  kivy,
  materialyoucolor,
  pillow,
}:
buildPythonPackage {
  pname = "kivymd";
  version = "2.0.1.dev0-unstable-2024-08-20";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kivymd";
    repo = "KivyMD";
    rev = "5ff9d0de78260383fae0737716879781257155a8";
    hash = "sha256-S6ZTaanYH+V+c9cW76lFiu1q+JVzPf5ejJI58hfrSvQ=";
  };

  build-system = [setuptools];

  dependencies = [
    asynckivy
    kivy
    materialyoucolor
    pillow
  ];

  meta = {
    description = "Set of widgets for Kivy inspired by Google's Material Design";
    homepage = "https://github.com/kivymd/KivyMD";
    license = lib.licenses.mit;
  };
}
