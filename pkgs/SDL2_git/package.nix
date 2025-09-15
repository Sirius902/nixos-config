{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-15";
  src = prevAttrs.src.override {
    tag = null;
    rev = "2b06aa21d0fda1ecf07fad991e258ad2678933e3";
    hash = "sha256-YM4NQX7mL0SztHRLfLmcpVIeprp2c5/FEXzO3BuAn4k=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex"
          "release-(.*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
