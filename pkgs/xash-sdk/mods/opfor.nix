{
  xash-sdk,
  nix-update-script,
}:
xash-sdk.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-03-26";

  src = prevAttrs.src.override {
    rev = "f7ce421fde685fa252a003189d131dd4e5d2d8c4";
    hash = "sha256-g2Lqrx7y41tEJTCHAiziFGQJE3e6taI6stvHLZ0K0Ug=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      modDir = "gearbox";

      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=opfor"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
})
