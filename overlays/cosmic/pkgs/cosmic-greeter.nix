final: prev:
prev.cosmic-greeter.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-16";

  src = prevAttrs.src.override {
    tag = null;
    rev = "31912afaa1e9e9988ecebefb041bdc3bce34f337";
    hash = "sha256-hlu0EOeU2N3CnbKkd1GCpUGcq0dG5cudeV30ePc7jA8=";
  };

  cargoHash = "sha256-ElIy18uwkSYQEmc1AAmETBHRIzQNQaNcLQfRLIMwTl0=";

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
