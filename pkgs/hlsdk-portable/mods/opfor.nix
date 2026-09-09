{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-09-09";

  src = prevAttrs.src.override {
    rev = "1b3f1c3b23330a52352b65b24b2c01d578a1c75e";
    hash = "sha256-bEY1aRSKzrnzE5bQsXkDW1TxOsaFe7hsCnd2b2rAG98=";
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
