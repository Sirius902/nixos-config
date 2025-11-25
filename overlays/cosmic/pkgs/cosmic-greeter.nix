final: prev:
prev.cosmic-greeter.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "201d8a1bc408f4b92ecc9da074ace26a3098463d";
    hash = "sha256-ldB9t+WMN/K5Xk6wO4lZ6+VJIDNI2iAl9240iRsvNCg=";
  };

  cargoHash = "sha256-4yRBgFrH4RBpuvChTED+ynx+PyFumoT2Z+R1gXxF4Xc=";

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
