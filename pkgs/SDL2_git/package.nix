{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-10-15";
  src = prevAttrs.src.override {
    tag = null;
    rev = "876ce2b0e9a6c80f25568e42773f9ecfd61d9beb";
    hash = "sha256-rTq3oq9yde/WbLD0lgzCVAWb6z5iHyOJkqB2LZmSP7M=";
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
