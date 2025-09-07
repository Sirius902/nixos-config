{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-06";
  src = prevAttrs.src.override {
    tag = null;
    rev = "d713ca0d141fa0953c88ec5b878b1bd4bef7bc46";
    hash = "sha256-75PtzDyBZ+3F/kmNHePuAQABZDe9yC72Yy4ExjWYejY=";
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
