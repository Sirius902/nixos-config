final: prev:
prev.cosmic-protocols.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0-unstable-2025-09-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "d0e95be25e423cfe523b11111a3666ed7aaf0dc4";
    hash = "sha256-KvXQJ/EIRyrlmi80WKl2T9Bn+j7GCfQlcjgcEVUxPkc=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = final.nix-update-script {
        # FUTURE(Sirius902) From nixos-cosmic: "add if upstream ever makes a tag"
        # extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
