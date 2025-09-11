# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-10";

  src = prevAttrs.src.override {
    tag = null;
    rev = "cd1117080c026da61f1c7e6be55f893b3a2f87ef";
    hash = "sha256-H2eMYjJi9VXv6D5IREVjfqR46hC9dxT84lk9Ubpnhpk=";
  };

  cargoHash = "sha256-mBS+usjUSKQporohuo2xOtEMepGWrqyfo5nWBuZ1tiM=";

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
