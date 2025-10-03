{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-10-03";
  src = prevAttrs.src.override {
    tag = null;
    rev = "dbb14dbb750d37b7499a898a10f5900dc90228b9";
    hash = "sha256-dZPdNTBgJ+vW9v3D2dkpO96SBa8NDjG8t9GqCytAkyY=";
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
