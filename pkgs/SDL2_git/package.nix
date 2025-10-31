{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.58-unstable-2025-10-30";
  src = prevAttrs.src.override {
    tag = null;
    rev = "b093f00e1a50946a6104eae436e4ffe7379fee5f";
    hash = "sha256-9n2YQLtXqVL6i8C48znGMcm7qebAUyF3b1kXCl6Bl/Q=";
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
