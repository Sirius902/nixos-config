final: prev:
prev.cosmic-settings-daemon.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-10";

  src = prevAttrs.src.override {
    tag = null;
    rev = "66e5f1d82b4daa62b028139e93a58e471bc5ac9e";
    hash = "sha256-ktToq8qsXk9v2W4Y3NIqqXcsOz7GuR+WIi9LeeDdhEo=";
  };

  cargoHash = "sha256-TqDuBmmFL3JIJQPCbZ0eN9Fr8gqt2bbpMPvGFwkH2/s=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  buildInputs = (prevAttrs.buildInputs or []) ++ [final.openssl];

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
