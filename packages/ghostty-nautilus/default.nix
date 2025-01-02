{
  lib,
  stdenvNoCC,
  ghostty,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "ghostty-nautilus";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./ghostty-nautilus.py
    ];
  };

  buildInputs = [ghostty];

  installPhase = ''
    install -Dm644 "ghostty-nautilus.py" -t "$out/share/nautilus-python/extensions"
  '';
}
