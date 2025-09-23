final: prev:
prev.cosmic-player.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-21";

  src = prevAttrs.src.override {
    tag = null;
    rev = "e3aebf4ea85a90b6d1491dc24379df960cd4943a";
    hash = "sha256-EzH/HWHH3raHw4wUmBUgaHiDT329P86FdxWzVxGzprE=";
  };

  cargoHash = "sha256-DodFIfthiGFSvXWfPsPjFhNY6G7z3lb6pfc5HtUXhMo=";

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
