# TODO(Sirius902) Overlay new cosmic-panel to avoid crashes when disconnecting displays
# until the nixos-unstable version is newer.
final: prev:
prev.cosmic-panel.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "1afc1e85b9119baea9a9e8a47deadfdfb8b3677f";
    hash = "sha256-2T95y+2yWkBq/MPPv+52KmfVQDxOw7mmjQOzx+L6qkk=";
  };

  cargoHash = "sha256-m9tWSJ/77uD29k6FFxLNtyZCkR32LHy5lzCAEPH5uXw=";

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
