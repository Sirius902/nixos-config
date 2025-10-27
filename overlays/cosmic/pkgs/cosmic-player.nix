final: prev:
prev.cosmic-player.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "e9beecc1bfb7066a7712c8cb51274cd2efddad8f";
    hash = "sha256-+LMXtiUxal4xSmtG9vHDSZxwzyjOhmS6ZZ7HppB7p7w=";
  };

  cargoHash = "sha256-fnX5BkzRAetKxHZ9XyWdmG6TSxFqGJsmg16zlpYG9Ag=";

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
