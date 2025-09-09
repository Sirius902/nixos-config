final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-08";

  src = prevAttrs.src.override {
    tag = null;
    rev = "bd7fc2a2f22d96a4fec1f8e2fc092a6fa931a68a";
    hash = "sha256-Z1hwRZay2/tmjG8MmZou3fxOxnZZtW/yt9XPZ6OYRsw=";
  };

  cargoHash = "sha256-4zgiRLO/vMXgxZtl+9gTeneihY/pQUw25rWZlaq8aPo=";

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
