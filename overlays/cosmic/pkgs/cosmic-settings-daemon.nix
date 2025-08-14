final: prev:
prev.cosmic-settings-daemon.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-11";

  src = prevAttrs.src.override {
    tag = null;
    rev = "19f10525ff00d76558147ea060bd856a87122353";
    hash = "sha256-Uxl0Ku9O1HZCB+rHjNuZqKED9dVEAJph3XKWN8Vy5wM=";
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
