final: prev:
prev.cosmic-workspaces-epoch.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-06-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "30ca652b1e8c0e50ed5638e9023ceb48b2a82720";
    hash = "sha256-TzRed3tDflsgsZQwS+wJHWBYa8HA/l01s6XHpMI6ZyE=";
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
