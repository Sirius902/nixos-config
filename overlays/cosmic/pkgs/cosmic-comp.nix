# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f339e21479c05153864af79c8fb5d005dcff8abc";
    hash = "sha256-RHeQk1yBNnDN/efuDDWNLn9O7FQTYLBsbs+h+gxi+Xo=";
  };

  cargoHash = "sha256-Jaw2v+02lA5wWRAhRNW/lcLnTI7beJIZ43dqcJ60EP0=";

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
