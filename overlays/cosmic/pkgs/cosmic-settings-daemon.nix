final: prev:
prev.cosmic-settings-daemon.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "d67de203ced04c5b8ec3486d93e0e61876a8ee91";
    hash = "sha256-w+k0x+9GlbAEZshfwIcO6I8hVhHdARJn/CA7QBDOVCo=";
  };

  cargoHash = "sha256-1YQ7eQ6L6OHvVihUUnZCDWXXtVOyaI1pFN7YD/OBcfo=";

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
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
