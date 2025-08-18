final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "fbe004b0313d62f1b4e8837a85bfc3346d87a9ae";
    hash = "sha256-PdhFAQsvs7nZrUDOXVDkPjyZHz8PJgyCidMWibNAQNg=";
  };

  cargoHash = "sha256-G3hjE4QsBGAw+tgSoZlIBo9zbjCw8PqpPWSYsd4jnx0=";

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
