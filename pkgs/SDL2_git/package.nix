{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-29";
  src = prevAttrs.src.override {
    tag = null;
    rev = "b86119e320fb4d6b3b1ce541dd335ba70456d8db";
    hash = "sha256-8cORoK93dyiog+WkwTV7IBQGdRvjE/1AEVe24P1EDCo=";
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
