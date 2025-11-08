{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.58-unstable-2025-11-07";
  src = prevAttrs.src.override {
    tag = null;
    rev = "defed07a6be0352e7f9884157cb4ef211862673f";
    hash = "sha256-jVLExdwZvlRjvhilJtTs8tqETXCz8Tcg/XyAjKpvy4g=";
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
