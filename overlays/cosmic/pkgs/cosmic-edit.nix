final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-20";

  src = prevAttrs.src.override {
    tag = null;
    rev = "c125d5c95190aa51c548e74a0a209b052af1206e";
    hash = "sha256-x8jSFPw6cABZwIEewQzxvkxoMwfFdNAypKUJtMCelbk=";
  };

  cargoHash = "sha256-DoAPF06Jf2dQCEUPPYPHQSJ9UIBdMoogS/A/n8JyzRM=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
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
