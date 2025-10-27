# TODO(Sirius902) Overlay new xdg-desktop-portal-cosmic to maybe fix clipboard shenanigans
# until the nixos-unstable version is newer.
final: prev:
prev.xdg-desktop-portal-cosmic.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2477a1b39806fd0eb6831e38f0a32a81abb1a806";
    hash = "sha256-EkhOa1Tircgyta98Zf4ZaV/tR4zZh4/bU35xjn3xU8c=";
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
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
