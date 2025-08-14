final: prev:
prev.cosmic-session.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-06-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "b2f42771222b1d0acd267355a83776abd465eff7";
    hash = "sha256-gGpDKPxlEcT8PA+9Pbktm49sI+gPTyVtPnuimqYALEk=";
  };

  cargoHash = "sha256-4leO8F32O4E+fqpR0/Nj5wBcY0N00J/JdsYnPwPCWps=";

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
