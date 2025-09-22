final: prev:
prev.cosmic-osd.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "fc095b351ba03011c384b89170d9557a6052f390";
    hash = "sha256-tsP4dlHmzuf5QgByDWbuigMrpgnJAjuNsYwWDSutCoI=";
  };

  cargoHash = "sha256-YcNvvK+Zf8nSS5YjS5iaoipogstiyBdNY7LhWPsz9xQ=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  # No longer needed due to https://github.com/pop-os/cosmic-osd/commit/4970139d875f9b28ea72d431e07ca3650a200470.
  postPatch = null;

  # FUTURE(Sirius902) cosmic-osd now depends on pipewire and libclang. Remove these if it is added upstream.
  nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [final.rustPlatform.bindgenHook];

  buildInputs =
    (prevAttrs.buildInputs or [])
    ++ [
      final.pipewire
      final.libinput
    ];

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
