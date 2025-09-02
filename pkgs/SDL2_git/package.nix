{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-08-28";
  src = prevAttrs.src.override {
    tag = null;
    rev = "ff4a64cd22599b6b4a21352485815ddef994cbba";
    hash = "sha256-u4iGtmtvQFA+6Z3GFnd+WA4YiQRXYceHzQ76PA16VnQ=";
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
