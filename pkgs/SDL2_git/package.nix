{
  lib,
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-04";
  src = prevAttrs.src.override {
    tag = null;
    rev = "32909905fd72467c74f3c7b5bcb5d77491afc7af";
    hash = "sha256-GjZviz1yLmq8lGwwQn1n4wkf6Nn7/o514A1C3G+KC/k=";
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

  meta =
    prevAttrs.meta
    // {
      changelog = "https://github.com/libsdl-org/sdl2-compat/releases/tag/release-${builtins.elemAt (lib.splitString "-" finalAttrs.version) 0}";
    };
})
