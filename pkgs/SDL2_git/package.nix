{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-10";
  src = prevAttrs.src.override {
    tag = null;
    rev = "8df91f96cb5c97776d5d9d1637c7e22caaa795c5";
    hash = "sha256-LQcXBPriaXsLp9thp19BqD1O4MF69ejg6myNB8tZtTY=";
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
