final: prev:
prev.cosmic-osd.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "fc095b351ba03011c384b89170d9557a6052f390";
    hash = "sha256-tsP4dlHmzuf5QgByDWbuigMrpgnJAjuNsYwWDSutCoI=";
  };

  cargoHash = "sha256-YcNvvK+Zf8nSS5YjS5iaoipogstiyBdNY7LhWPsz9xQ=";

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
