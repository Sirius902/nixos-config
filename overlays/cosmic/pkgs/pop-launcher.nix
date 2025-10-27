final: prev:
prev.pop-launcher.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.2.6-unstable-2025-09-25";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0e8aa22f970ae228bed5573f640cac01eb706a37";
    hash = "sha256-4wPspv5bpqoG45uUkrtxJTvdbmFkpWv8QBZxsPbGu/M=";
  };

  cargoHash = "sha256-gc1YhIxHBqmMOE3Gu3T4gmGdAp0t+qiUXDcPYZE6utU=";

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
      updateScript = final.nix-update-script {};
    };
})
