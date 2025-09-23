final: prev:
prev.cosmic-randr.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-07";

  src = prevAttrs.src.override {
    tag = null;
    rev = "bce9cdf2d447508d4e2d54a2be4fcd738ab51df5";
    hash = "sha256-daP2YZ7B1LXzqh2n0KoSTJbitdK+hlZO+Ydt9behzmQ=";
  };

  cargoHash = "sha256-tkmBthh+nM3Mb9WoSjxMbx3t0NTf6lv91TwEwEANS6U=";

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
