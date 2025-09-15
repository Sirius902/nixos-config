final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "b30df8987ce5c5013cf5025238a19ffb1da297bc";
    hash = "sha256-ceT2FmdNZcZi6vIsAlnDEfpGuV1sWAwnORyBHAKkqMI=";
  };

  cargoHash = "sha256-0pmENYRK9gt3Zytc0/2XX0NFLe0EbC2JBwCWOJEFj8k=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  # FUTURE(Sirius902) cosmic-edit now depends on glib. Remove this if it is added upstream.
  buildInputs = (prevAttrs.buildInputs or []) ++ [final.glib];

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
