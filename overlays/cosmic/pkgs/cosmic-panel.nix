# TODO(Sirius902) Overlay new cosmic-panel to avoid crashes when disconnecting displays
# until the nixos-unstable version is newer.
final: prev:
prev.cosmic-panel.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-01";

  src = prevAttrs.src.override {
    tag = null;
    rev = "9adf94ebefc7dba5e58dd051e6efa87d058d11aa";
    hash = "sha256-mYfV5INjsF0lG523ZDgKFgGiv8bzrvvxqQ84JlWLVVQ=";
  };

  cargoHash = "sha256-Q30v5dd2iAMJKdeDapQBMeyusDfdX4yAw15I0b90SvM=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
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
