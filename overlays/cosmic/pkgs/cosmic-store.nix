final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "1a9be524799bb033f39ce6b47eb41c08b713e362";
    hash = "sha256-l2IHaujVze3bpzSMifZfVBGwE0ajjjHxmpO339jG+TU=";
  };

  cargoHash = "sha256-xdNYQB/zmndnMAkstwJ6Z2uk0fXli3gIYHchUq/3u6k=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
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
