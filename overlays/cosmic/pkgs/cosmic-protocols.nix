final: prev:
prev.cosmic-protocols.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0-unstable-2025-09-17";

  src = prevAttrs.src.override {
    tag = null;
    rev = "af1997b1827ad64aab46fa31c0b77fb20d7a537a";
    hash = "sha256-gIfCk8FqZo1iFwTTtcLqnX14Jg3k6UXIBkpKsom43EU=";
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
