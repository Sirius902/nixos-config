final: prev:
prev.cosmic-workspaces-epoch.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0375f28bb29e4a7c83b313735544b434cf9414ec";
    hash = "sha256-xyM3w4et92jFc0mm7XwWHGzVjc0u11F0u4p3J3s7M/s=";
  };

  cargoHash = "sha256-wFX5EReAnZ7ymXYfMfiZU1MeUUCcOKEkWdSeyGHEuKg=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
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
