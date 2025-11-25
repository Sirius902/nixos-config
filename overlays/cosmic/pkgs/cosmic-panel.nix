final: prev:
prev.cosmic-panel.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "8f445a4ce944b6422e6310da06ad15a311c2bbf8";
    hash = "sha256-gvEHieM8osGyRrkeE8gEOPduTv3y3KgoZ2YhFgW5qp8=";
  };

  cargoHash = "sha256-ZkjXZrcA4qKHSjEOxj7+j10PxJw/du8B2Mee2fxPJxs=";

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
