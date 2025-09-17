final: prev:
prev.cosmic-greeter.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-17";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7f9b7e42dc6225ad87281f09454a04ecdbec6b5f";
    hash = "sha256-nNLtYnZYK3wuAZhKNi5Dbb2i8Fn1RBq4g5F8S1gGuQA=";
  };

  cargoHash = "sha256-qioWGfg+cMaRNX6H6IWdcAU2py7oq9eNaxzKWw0H4R4=";

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
