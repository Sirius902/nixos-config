final: prev:
prev.cosmic-bg.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f1f79d33892cc47c558d33250ae6a2fc9d9dbff0";
    hash = "sha256-mF6W/RND9cNfS27lQNZRcXY4OUMS+UUMMcEalBQ59Yg=";
  };

  cargoHash = "sha256-+NkraWjWHIMIyktAUlp3q2Ot1ib1QRsBBvfdbr5BXto=";

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
