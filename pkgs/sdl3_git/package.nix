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
    rev = "976ba1e7504f12ca08a2637380aa73e46651f7aa";
    hash = "sha256-L4Mcl4gfmg81bhce12p3K/vI0Rx45Jbovgdn2DArfp4=";
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
