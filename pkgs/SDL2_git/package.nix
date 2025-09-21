{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-21";
  src = prevAttrs.src.override {
    tag = null;
    rev = "e47c7c7fbd8ab81913ce3d5bda511363bb618982";
    hash = "sha256-IvzqE8YZgwAojIP2KOmnzwOiDXf2qaK31NEpi4HvmmM=";
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
