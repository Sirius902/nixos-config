{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-18";
  src = prevAttrs.src.override {
    tag = null;
    rev = "1e2057f1feb88b3d86929f2bc8d540a60cdf796b";
    hash = "sha256-7RfgGCyNoTh6msj4H0tb47bBF/a2ttRm7lMPt/7zCnQ=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex"
          "release-(3\\..*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
