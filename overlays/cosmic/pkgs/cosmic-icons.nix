final: prev:
prev.cosmic-icons.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-03-21";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0b2aed444daa52c65effbb8e71a8a19b0f2e4cb9";
    hash = "sha256-KDmEYeuiDTYvqg2XJK8pMDfsmROKtN+if5Qxz57H5xs=";
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
