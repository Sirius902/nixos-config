final: prev:
prev.cosmic-session.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-20";

  src = prevAttrs.src.override {
    tag = null;
    rev = "4c72d42731f96cf146c1ab664d0cc4f292e2527b";
    hash = "sha256-7xVOMwAYmm2G9NURvYh3+9mxq4/nCFBCL9bOlo92yNU=";
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
