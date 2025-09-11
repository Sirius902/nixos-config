final: prev:
prev.cosmic-workspaces-epoch.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-11";

  src = prevAttrs.src.override {
    tag = null;
    rev = "a939335b9ee6660b759d19dc6abd0b0adfbdb82f";
    hash = "sha256-Wm0U41vkd9O7btV/Dju8nSH9vn64A1s2xn4t/bOMJX8=";
  };

  cargoHash = "sha256-tfC6cJMiun7O5tBrxpffCicaKRMGbCPi2oWISMvB8ZM=";

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
