final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-28";

  src = prevAttrs.src.override {
    tag = null;
    rev = "e21ad9f27c88742e9057a13b7f6619ed7dd67845";
    hash = "sha256-q5GFizyPPfbXIgWJtTzgDSxehPA2tdppS8uwIDVRcKQ=";
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
