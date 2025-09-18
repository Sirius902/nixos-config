# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "b75be5b305d1633489eb204ba23e5af2f1e9611a";
    hash = "sha256-tWMcdPzQgVjWAaKon5uR4/H3/OoE07ETqCpTWsqXOZI=";
  };

  cargoHash = "sha256-TeEZrIFZ+q8jWa5uZrjNRG90dKb9gTEJ+2o8m9Hnrvk=";

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
