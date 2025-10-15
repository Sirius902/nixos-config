{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-10-13";
  src = prevAttrs.src.override {
    tag = null;
    rev = "26aabf38f17a90e7c49c05cd417d073ad852e8ea";
    hash = "sha256-jO/tHdBZiPXRU73t1ojB3LQ6fZ731gbBmT6qXgAtAm4=";
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
