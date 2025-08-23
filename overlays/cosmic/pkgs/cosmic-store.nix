final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "06651b6135a9500b629ebab3b7d2041e4f26a911";
    hash = "sha256-DTfxHJvV3YqJgbkMKBxebdlsD1cKRlHcrIPUNKTx39Q=";
  };

  cargoHash = "sha256-zkmfYOHGwKbAn6QINp8iX4/WG/xHqoT8lGP/zjICjBE=";

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
