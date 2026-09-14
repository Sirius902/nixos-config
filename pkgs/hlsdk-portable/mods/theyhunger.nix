{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-09-13";

  src = prevAttrs.src.override {
    rev = "be67e259de6042e5143e250dece795905a44b203";
    hash = "sha256-1nkkCHsUN3TBMsAYelbJ1lFvP5wACI02OTsuRizqNzs=";
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
