final: prev:
prev.cosmic-launcher.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "b411aa6bb33399642795aca9ad002ddf0b7a7dcd";
    hash = "sha256-vAuWH9qmstPcfPvcKoM/2VjGxAfdtO9hhOPaZ5Ft4Y0=";
  };

  cargoHash = "sha256-57rkCufJPWm844/iMIfULfaGR9770q8VgZgnqCM57Zg=";

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
