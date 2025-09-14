final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-14";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f39eef77621c0c3aff33723ef1d1c7affccc80f4";
    hash = "sha256-GpeCnvIt9IYaXkkeOsx0joCgck61p74xg8qywFnzAYg=";
  };

  cargoHash = "sha256-X6XTanAFQFTxs1w7As3QpRcSRCbSTEJmo7HTG6bk4v4=";

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
