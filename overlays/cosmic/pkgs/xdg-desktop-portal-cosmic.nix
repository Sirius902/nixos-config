# TODO(Sirius902) Overlay new xdg-desktop-portal-cosmic to maybe fix clipboard shenanigans
# until the nixos-unstable version is newer.
final: prev:
prev.xdg-desktop-portal-cosmic.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "100ed29395c78a3d3181d94bd74c5d2425c8a537";
    hash = "sha256-2eTbp5qPLdJV4VrULyQxzuEfoVi+ZSeS9F5bY5CADu4=";
  };

  cargoHash = "sha256-48gK3rRmtvXmmY6Ut5qd94/aGq7UyYZvtCipWgiSGLg=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = final.nix-update-script {
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
