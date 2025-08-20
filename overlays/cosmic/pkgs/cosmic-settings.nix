final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-20";

  src = prevAttrs.src.override {
    tag = null;
    rev = "c8036c79170118a39c48d9930acd5bd2725bed92";
    hash = "sha256-CFVkk5SJGAKpxlE1uEx9SLhFwhjWvfMhMVxImmJf3NM=";
  };

  cargoHash = "sha256-lPAtrV4ZrbhlC4P0TA/PuNc/LeCiflru6MYxYYN2qH8=";

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
