final: prev:
prev.cosmic-notifications.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-07-25";

  src = prevAttrs.src.override {
    tag = null;
    rev = "744439a6e79f7bcb74ba861d525318f9b774c7f5";
    hash = "sha256-Yymjsj+3aeaP8pv4jO2VKVOrADE2sBVar92ElVVUJgw=";
  };

  cargoHash = "sha256-3rBbjAVdpNKYBHOrI/Zsb4Q5J9Xx4ddeCpzsUK51mns=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
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
