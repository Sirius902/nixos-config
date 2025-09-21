final: prev:
prev.cosmic-launcher.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-21";

  src = prevAttrs.src.override {
    tag = null;
    rev = "57fa65b5931ebfcfc06dbfdeeb72c77bed091133";
    hash = "sha256-n8SxxheXJd1yQebagDI/4bB1bpG7w0E3gF8gDUYolNE=";
  };

  cargoHash = "sha256-57rkCufJPWm844/iMIfULfaGR9770q8VgZgnqCM57Zg=";

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
