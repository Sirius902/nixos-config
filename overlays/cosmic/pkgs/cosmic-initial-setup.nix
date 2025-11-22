final: prev:
prev.cosmic-initial-setup.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-11";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f8cba7d2f658e2bf61b99e89ca7afc32c2fb75a3";
    hash = "sha256-8dnReeMxkbu965x8VgTg3C6IPSK3wcqT1r0rklPksAw=";
  };

  cargoHash = "sha256-jOPJiKPE3UUD/QHmb+6s6l2RVhtUFls3QRGQ6DmEFSE=";

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
