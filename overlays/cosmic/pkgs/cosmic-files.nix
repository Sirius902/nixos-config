final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7cc28a9b68630f0701a71bdb2b80b120990f4c4b";
    hash = "sha256-DbxA2lAPVNdel02NeuACucCyGcsNjT0MxJMzeGF3JzY=";
  };

  cargoHash = "sha256-TovOJVe16VJZ9Ul2JQc/No8f0WzaYfWI1LmzhHxdKsM=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  passthru.updateScript = final.nix-update-script {
    extraArgs = ["--version-regex=epoch-(.*)"];
  };
})
