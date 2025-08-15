final: prev:
prev.cosmic-player.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "58c778832b188df676a5cb8e3b18f4a27f4636d7";
    hash = "sha256-QLyedS2bfn0iQrrlbOswhPLb1R/AK7z25TfQyF9p1rc=";
  };

  cargoHash = "sha256-DodFIfthiGFSvXWfPsPjFhNY6G7z3lb6pfc5HtUXhMo=";

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
