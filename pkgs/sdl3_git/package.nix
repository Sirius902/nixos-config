{
  lib,
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-04";
  src = prevAttrs.src.override {
    tag = null;
    rev = "a9b5a1e785329f9b9c95c32608954c20ac44ce8d";
    hash = "sha256-ezdVAoHffQJ0XR5NnoooO8dMhNzZnUQHbSm9Xh+I7Go=";
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
