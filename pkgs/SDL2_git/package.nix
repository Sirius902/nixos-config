{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-10-26";
  src = prevAttrs.src.override {
    tag = null;
    rev = "58d64831e792c0a53285981fbc644bb96915fca5";
    hash = "sha256-bGSCyOMabBHki9k51AwHLo+f8QOUXcMGl2dMZRopTdc=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex=release-(.*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
