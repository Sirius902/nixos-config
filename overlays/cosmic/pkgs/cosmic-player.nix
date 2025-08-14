final: prev:
prev.cosmic-player.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "21866486bd207e7654a19ede7829bf5eb35b5475";
    hash = "sha256-Misdcb/szhvdEp5ZR0EmGCWKShLGbXd/OkMB3rjmCu8=";
  };

  cargoHash = "sha256-0RrtErTR2J5mn/Lfppk+5X8UUOC2LN65krAq1uz/O4M=";

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
