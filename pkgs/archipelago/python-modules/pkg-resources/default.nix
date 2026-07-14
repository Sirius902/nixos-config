{
  lib,
  buildPythonPackage,
  fetchPypi,
  python,
  jaraco-text,
  packaging,
  platformdirs,
}:
buildPythonPackage rec {
  pname = "pkg-resources";
  version = "80.9.0";
  format = "wheel";

  src = fetchPypi {
    pname = "setuptools";
    inherit version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    hash = "sha256-Bi00IirRPgzDEqTALXPwWehqSsv73qj492soyZ8waSI=";
  };

  dependencies = [
    jaraco-text
    packaging
    platformdirs
  ];

  postInstall = ''
    rm -r \
      $out/${python.sitePackages}/setuptools \
      $out/${python.sitePackages}/_distutils_hack \
      $out/${python.sitePackages}/distutils-precedence.pth \
      $out/${python.sitePackages}/setuptools-${version}.dist-info
  '';

  pythonImportsCheck = ["pkg_resources"];

  meta = {
    description = "Runtime pkg_resources module from the last setuptools release to ship it";
    homepage = "https://github.com/pypa/setuptools";
    license = lib.licenses.mit;
  };
}
