final: prev:
prev.cosmic-wallpapers.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-04-08";

  src = prevAttrs.src.override {
    tag = null;
    rev = "189c2c63d31da84ebb161acfd21a503f98a1b4c7";
    hash = "sha256-XtNmV6fxKFlirXQvxxgAYSQveQs8RCTfcFd8SVdEXtE=";
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
