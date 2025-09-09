# TODO(Sirius902) Overlay new cosmic-panel to avoid crashes when disconnecting displays
# until the nixos-unstable version is newer.
final: prev:
prev.cosmic-panel.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-08";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2bd1a6f8e42b3857853a23b097daf2ab45eb0e18";
    hash = "sha256-VbXdXo3K5UN25B2+ZWdP8EzX4M3553ZjPaXRQenU3Ys=";
  };

  cargoHash = "sha256-m9tWSJ/77uD29k6FFxLNtyZCkR32LHy5lzCAEPH5uXw=";

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
