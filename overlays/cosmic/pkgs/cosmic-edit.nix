final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "b4b6f21e3ecea797ab684e0ee29c690fc5f28a15";
    hash = "sha256-eu47WJbXsWb8lydMt2p0Zq36T6UL9kbgNMwU6JTQh88=";
  };

  cargoHash = "sha256-YfD06RAQPZRwapd0fhNsZ0tx+0JMNDXiPJIWwDhmG0M=";

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
