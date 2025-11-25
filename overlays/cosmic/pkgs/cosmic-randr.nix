final: prev:
prev.cosmic-randr.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "c39fe3fe3573c34ebbdf6d6d7f93ff232800c588";
    hash = "sha256-g5s4TIk8nS3qPIAlWQC4D5A936+DYMbEEnU6v8iO9TI=";
  };

  cargoHash = "sha256-ZStjzRqgCnRy1v2K1upUbioedmDaa1ml1gRNZc32Q00=";

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
