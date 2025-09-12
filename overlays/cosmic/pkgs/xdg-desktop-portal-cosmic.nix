# TODO(Sirius902) Overlay new xdg-desktop-portal-cosmic to maybe fix clipboard shenanigans
# until the nixos-unstable version is newer.
final: prev:
prev.xdg-desktop-portal-cosmic.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "a069d57d359c4fe25a0415bdfee6c967e07b5a48";
    hash = "sha256-jwLTgzchY18rPbc93DEADmJ2XHkLBsO002YoxWbCq2Y=";
  };

  cargoHash = "sha256-uJKwwESkzqweM4JunnMIsDE8xhCyjFFZs1GiJAwnbG8=";

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
        extraArgs = [
          "--version-regex"
          "epoch-(.*)"
        ];
      };
    };
})
