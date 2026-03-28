{
  xash-sdk,
  nix-update-script,
}:
xash-sdk.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-03-26";

  src = prevAttrs.src.override {
    rev = "cf57ec1294b020a49742ee626cea59d7512f03cd";
    hash = "sha256-iLa1cNSV7xj91652O3yZ2YkSBBgWpOmzQQ/hYR/5g8g=";
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
