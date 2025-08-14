final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-14";

  src = prevAttrs.src.override {
    tag = null;
    rev = "d928f3f4d5163525c503436fc8dee4ef65199423";
    hash = "sha256-jC51RGdGTJAzuWeSpurDIVSvv1c8G/RyAWdO/Oj/YGo=";
  };

  cargoHash = "sha256-LTdI5H7QbDKTqIoPwYsddxU/4ujJv8k2oXa2INIzeJw=";

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
