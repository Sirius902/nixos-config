final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3c3aa72dc8b0d09fb55770f8661354014e00b24a";
    hash = "sha256-8EkSOOORqXDhW+KPNeU1VJ6SLbrlGZGCsauUYYkznmI=";
  };

  cargoHash = "sha256-mMfKY+ouszbN2rEf6zvv1Sc1FEZ/ZVuQ6RXGMBFDwIE=";

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
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
