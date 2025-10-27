final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-25";

  src = prevAttrs.src.override {
    tag = null;
    rev = "c13ec4b41b557ec00c3f71e450cedca0c96603a3";
    hash = "sha256-U1/6IgnqNN9ccnh0IFuDkkurFN0JxmXJltns6Vv6/9A=";
  };

  cargoHash = "sha256-oiZjX53CQA53mMNfmmnyzWGAiZRA+4BxOxEvbEFd8q8=";

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
