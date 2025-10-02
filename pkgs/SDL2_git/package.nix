{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-10-02";
  src = prevAttrs.src.override {
    tag = null;
    rev = "afa1378f10e246d0fb6833c97e29b23f703cebe4";
    hash = "sha256-IMdR676Bu1MSqWXd7cN/Y7MZPCuKTg4I3OXxhH3NCd8=";
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
