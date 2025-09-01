final: prev:
prev.cosmic-protocols.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0-unstable-2025-09-01";

  src = prevAttrs.src.override {
    tag = null;
    rev = "6254f50abc6dbfccadc6939f80e20081ab5f9d51";
    hash = "sha256-gOYgz07RGZoBp2RbHn0jUGLGXH/geoch/Y27Qh+jBao=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = final.nix-update-script {
        # FUTURE(Sirius902) From nixos-cosmic: "add if upstream ever makes a tag"
        # extraArgs = [
        #   "--version-regex"
        #   "epoch-(.*)"
        # ];
      };
    };
})
