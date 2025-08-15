final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "1a37a81b662f91dc6e5d95193c96d1d7151fff6f";
    hash = "sha256-ZE7gOxlVbL03dtFkIYdH+TaMQJbLDPwjdz5XRRXMU0s=";
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
