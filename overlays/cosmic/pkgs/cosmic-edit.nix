final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-16";

  src = prevAttrs.src.override {
    tag = null;
    rev = "140e6aab885b7680dc042d86ea62f8fb5c4838c2";
    hash = "sha256-zXYgfUzxz21tj/C4GWb5/V8mnxU/HmgPcEvLhny2pKw=";
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

  # FUTURE(Sirius902) cosmic-edit now depends on glib. Remove this if it is added upstream.
  buildInputs = (prevAttrs.buildInputs or []) ++ [final.glib];

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
