final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "db805990b6b864d19d3dfff144965802da40f7d0";
    hash = "sha256-pNMmkXQjQ66o21rxqXR3U2f4aLFASsRfw/R+qloBln8=";
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
