final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "35882a70d9a430429b0c51d9d024ffda623deb7b";
    hash = "sha256-qxWk4drNxNOuDvAQsYywXEhQOBdsvlX/l9ozr+wD8HA=";
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
