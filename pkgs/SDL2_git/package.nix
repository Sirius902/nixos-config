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
    rev = "2b0faaa1ea3c2b8275a08e3ae2a1be58642e23de";
    hash = "sha256-E3JcbFbok+BC4TNoryNKbg3yQ9g8DFka9MwGhT+Be00=";
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
