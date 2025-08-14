final: prev:
prev.cosmic-protocols.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0-unstable-2025-08-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "8e84152fedf350d2756a2c1c90e07313acb9cdf6";
    hash = "sha256-rFoSSc2wBNiW8wK3AIKxyv28FNTEiGk6UWjp5dQVxe8=";
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
