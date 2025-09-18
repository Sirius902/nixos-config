{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-18";
  src = prevAttrs.src.override {
    tag = null;
    rev = "facb732f7e295a48691f01a03ecb4e0f7d0decdd";
    hash = "sha256-7ErjRUtM1b7oGigR4KA6ZZUimqtC/fUYM//1fXwmITU=";
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
