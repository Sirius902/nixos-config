{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-09-09";

  src = prevAttrs.src.override {
    rev = "ac8e718892aa3c311311cfa0369dd8d951c50fa5";
    hash = "sha256-WGjL9tOVEzppD6/k+bD9hvJcmcgIDHSSU4D+p0l+PSk=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      modDir = "Hunger";

      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=theyhunger"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
})
