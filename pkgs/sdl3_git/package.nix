{
  lib,
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-05";
  src = prevAttrs.src.override {
    tag = null;
    rev = "a6dc61ab321cfe5a8f31a723f813be03191bb941";
    hash = "sha256-3g6SocO9YZ/X3Ubp3upTvlbBnu6lQVO38Rjz5ghnDAg=";
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
