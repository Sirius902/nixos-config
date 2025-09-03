{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-03";
  src = prevAttrs.src.override {
    tag = null;
    rev = "637a9b34abd7ba6612e888219bacefa1bfb1c01d";
    hash = "sha256-HB97MX4nDqGPgHPSXuiQ/SxGg08Y0ylIXhdcvX3+MLU=";
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
