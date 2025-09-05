final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-05";

  src = prevAttrs.src.override {
    tag = null;
    rev = "cabed2fcfd91ca510d7c2f3119e80e297462c8a0";
    hash = "sha256-LXg8SF/BmA6sqkNAWi0pbpbqRZz5BVkuT/qCcJRiE8k=";
  };

  cargoHash = "sha256-wMkED3KyVy9gDpYDNLtPIn2IDA1U0tKBxKvz86VAH94=";

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
