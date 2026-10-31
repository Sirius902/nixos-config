{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-10-31";

  src = prevAttrs.src.override {
    rev = "0c574ee1096eeb78070c90cb56238d7f45d7f7f0";
    hash = "sha256-2+CdLeK8AbIDppL/V3vMvSXF+oiZ9njG+3X4JdZtJvE=";
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
