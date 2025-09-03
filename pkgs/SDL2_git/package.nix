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
    rev = "469d0b7a0509a1329b8ab1aa38faa1b341614e72";
    hash = "sha256-3TewdJSCpsvRfb17Uq9OpQxBlUnGRH7O0nrlIaw4Ayg=";
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
