{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-10-08";
  src = prevAttrs.src.override {
    tag = null;
    rev = "e6b699c824baadbf336c94efdc881602656c1f3a";
    hash = "sha256-GKp036yZmliHVj8QvEHBRmNNwHr1b5gEBpbmREdCv6s=";
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
