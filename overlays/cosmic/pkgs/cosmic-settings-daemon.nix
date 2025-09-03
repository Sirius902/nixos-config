final: prev:
prev.cosmic-settings-daemon.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-03";

  src = prevAttrs.src.override {
    tag = null;
    rev = "ff15f3240f6cf36ea74eacbf55ad805377e88a41";
    hash = "sha256-xhscc4S+TdZh56I4D2Xo8C+q40jil1rAanaxx+HwUPE=";
  };

  cargoHash = "sha256-TqDuBmmFL3JIJQPCbZ0eN9Fr8gqt2bbpMPvGFwkH2/s=";

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
