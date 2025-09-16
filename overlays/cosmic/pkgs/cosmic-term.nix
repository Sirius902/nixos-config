final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-16";

  src = prevAttrs.src.override {
    tag = null;
    rev = "6f06badab03ff1b58e92ed75062060915dabb79a";
    hash = "sha256-ktpDf8SJVW1W/gPDFv7F8U5b18aNaTB8VI2zpw2FwEs=";
  };

  cargoHash = "sha256-zfby5QMDZzJhRvsf07QRBw2/DFX7BmiNByOLQegBbmo=";

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
