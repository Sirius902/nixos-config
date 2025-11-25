final: prev:
prev.cosmic-idle.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "983d34ad9644930495e6d1c3ffb78408dad0c78d";
    hash = "sha256-qVrcMI7sr0mWyYW1fM6oP/6qKEhlqqyQ/WiJaWfCQPU=";
  };

  cargoHash = "sha256-vfuhXT/MJHchJdW+3GPuvZbYVdClpsbNfOzLKWW4LPY=";

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
