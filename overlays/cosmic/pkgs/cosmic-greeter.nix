final: prev:
prev.cosmic-greeter.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "79bf2cb4f896b84eb3e51068b7d4941b127e0ddd";
    hash = "sha256-krpoRFh6zmCwA++kaHyxnqAsmC+3vctRW718x9eAKU0=";
  };

  cargoHash = "sha256-42In98f6wLkv5rEow6ASditwfnowVTTkvR8kL7c8Dss=";

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
