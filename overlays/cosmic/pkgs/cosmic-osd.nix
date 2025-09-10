final: prev:
prev.cosmic-osd.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-07";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f826e1184eedf80235e35098515292f62a773674";
    hash = "sha256-hseWfOn4SvJ/gzKSYMQ9Museapg43kHYiqBqlaET6Pk=";
  };

  cargoHash = "sha256-qiQ4VV1ML2EpfxEdE/A8b6mhtnr5y1/Dr9BvtFu0zgg=";

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
