{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-03";
  src = prevAttrs.src.override {
    tag = null;
    rev = "a731e60df9dbc235b3ffa3b4e1c3db2d0c19222a";
    hash = "sha256-90Mklg5TBdCCUji0JMkjnKSnUFM4GLNUYwd2UUvxRX8=";
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
