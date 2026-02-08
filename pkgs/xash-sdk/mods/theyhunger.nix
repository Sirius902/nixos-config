{
  xash-sdk,
  nix-update-script,
}:
xash-sdk.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2025-08-17";

  src = prevAttrs.src.override {
    rev = "48ebea48f4f324d1a5855b8964fa947d59d69e05";
    hash = "sha256-BZkfmcFe+dSFnzTpicy5cuAL8jZy2r/LD7/mfg7QyH0=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      modDir = "Hunger";

      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=theyhunger"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
})
