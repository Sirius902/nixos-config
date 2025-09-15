final: prev:
prev.cosmic-applets.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "8196fc642509fe644e45529e2df0fd08796aaf71";
    hash = "sha256-utowiRqDkzmofglKd3Uwz7YqYqAW8Q68FmccIzLrN2c=";
  };

  cargoHash = "sha256-B+V5hw/gGUOrmsVf25ZvYDVPOq350v1YJB7wpHI0ioU=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  # FUTURE(Sirius902) Remove this if upstream removes the bluetooth spam patch (already applied here).
  patches = builtins.filter (p: p.name != "fix-bluetooth-dbus-spam.patch") (prevAttrs.patches or []);

  # FUTURE(Sirius902) cosmic-applets now depends on pipewire and libclang. Remove these if it is added upstream.
  nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [final.rustPlatform.bindgenHook];

  buildInputs = (prevAttrs.buildInputs or []) ++ [final.pipewire];

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
