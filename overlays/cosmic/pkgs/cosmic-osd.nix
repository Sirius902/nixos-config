final: prev:
prev.cosmic-osd.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "8c35926f25cb67612f58eb8481d06574922675cc";
    hash = "sha256-t6mtACR8xRm/676H7ki/t8EPRLZotLTgoLKKPilIJlw=";
  };

  cargoHash = "sha256-9XUDMf+rDHrpPK07EoF1dpcCqqbkYzhaTu/p9ckmTNk=";

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
