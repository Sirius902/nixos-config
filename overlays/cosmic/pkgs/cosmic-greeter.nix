final: prev:
prev.cosmic-greeter.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-14";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f1f7862fbc270ea22db136f8feea027400d3be0f";
    hash = "sha256-Ntq50O++1Lb3w326HjML53sAa4zlxG6tEXHWkjT/ENM=";
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
