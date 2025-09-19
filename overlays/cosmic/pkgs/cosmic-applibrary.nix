final: prev:
prev.cosmic-applibrary.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0c1965cc0cec234425ae132f38df452849660aa9";
    hash = "sha256-ka5idl8msH0gzh+In9Sd7rGzBE8ZLaa1y09c7AtqXEk=";
  };

  cargoHash = "sha256-f5uMgscentTlcPXFSan1kKcKh1nk88/3kQPTSuc0wz4=";

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
