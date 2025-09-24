{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-24";
  src = prevAttrs.src.override {
    tag = null;
    rev = "1577bce925167bb595d42cae21d8ca2e81face2c";
    hash = "sha256-9DmhrI63tcPY1BgwCEygP8V7dKmgObx74fofxVR/SnE=";
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
