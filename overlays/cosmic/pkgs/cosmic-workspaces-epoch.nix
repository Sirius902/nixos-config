final: prev:
prev.cosmic-workspaces-epoch.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "d3fc7a2815107e368d51087650e4819cc47d7828";
    hash = "sha256-e96RneJeYimPmO1ndl4cbMEVpJ9t2ENZi7d/zOe6Wvc=";
  };

  cargoHash = "sha256-ICZSp1lE8he+aQN9zjdHF9gGy2KqcVX7xZwtCd8ar6U=";

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
