{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-10-11";
  src = prevAttrs.src.override {
    tag = null;
    rev = "d03512e13310625da8f26115db3f2f9fc801699d";
    hash = "sha256-b8FQvLbJyJ6z8kjM+eqpQTYO82L2gJP/sG7BOCUL07U=";
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
