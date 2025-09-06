{
  lib,
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-06";
  src = prevAttrs.src.override {
    tag = null;
    rev = "baf965c1ca4d12e91d9785623f827f10a59dbc73";
    hash = "sha256-9oW3gBXfEtcQk07t/ukNSTEhADlb8JfZnSfbbjOX9wg=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex"
          "release-(3\\..*)"
        ];
      };
    };

  meta =
    prevAttrs.meta
    // {
      changelog = "https://github.com/libsdl-org/SDL/releases/tag/release-${builtins.elemAt (lib.splitString "-" finalAttrs.version) 0}";
    };
})
