final: prev:
prev.cosmic-settings-daemon.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3f72461e99ed9acaccd3199d8888cf619dc5f511";
    hash = "sha256-Y9JtCXTjtIbUJs4UEedeyH7uWOcbHpWJqubkMND1RiU=";
  };

  cargoHash = "sha256-9BeC0Y29NOMoEJHKLV3aRHZQbglbLnnTH4uS3h129iw=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  buildInputs = (prevAttrs.buildInputs or []) ++ [final.openssl];

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
