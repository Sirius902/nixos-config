{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-15";
  src = prevAttrs.src.override {
    tag = null;
    rev = "964bedfdd906673944ea5fce52c2e748a62f4994";
    hash = "sha256-EIGXJO2wPoL9z5Vh6hMlQk6K0Z10aBhUe3whULUvC50=";
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
