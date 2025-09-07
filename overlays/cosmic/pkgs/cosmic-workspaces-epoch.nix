final: prev:
prev.cosmic-workspaces-epoch.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-07";

  src = prevAttrs.src.override {
    tag = null;
    rev = "05c9af1b95e55319f2b170c7d32ed05e9bd49f3c";
    hash = "sha256-hDk0vTiadiriaZpFhRDHRd7+maRR0wVGXOR8Sb4HDII=";
  };

  cargoHash = "sha256-wFX5EReAnZ7ymXYfMfiZU1MeUUCcOKEkWdSeyGHEuKg=";

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
