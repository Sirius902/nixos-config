# `nautilus-python` must be installed in system packages or else the context menu will
# not appear.
{
  lib,
  stdenvNoCC,
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

  installPhase = ''
    runHook preInstall
    install -Dm644 "ghostty-nautilus.py" -t "$out/share/nautilus-python/extensions"
    runHook postInstall
  '';

  meta = {
    description = "Nautilus integration with Ghostty terminal";
    homepage = "https://ghostty.org";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
