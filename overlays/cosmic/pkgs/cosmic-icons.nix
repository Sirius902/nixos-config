final: prev:
prev.cosmic-icons.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "70b07582e24ec2114672256b9657ca80670bca8a";
    hash = "sha256-jxt0x0Ctk0PaaFQjf8p9y1yEgWkuEi7bR2VtybwlQAs=";
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
