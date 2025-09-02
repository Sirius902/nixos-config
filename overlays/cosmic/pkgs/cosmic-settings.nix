final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-02";

  src = prevAttrs.src.override {
    tag = null;
    rev = "814beb5950de9488687eb9afada3bbf600198c20";
    hash = "sha256-cYAmOefmOBvJQIz2zspGQMWx5Wxf1bTizIctIhe71Fg=";
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
