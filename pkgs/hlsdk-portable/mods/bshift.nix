{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-10-20";

  src = prevAttrs.src.override {
    rev = "ebc703ef52aef4d4623a2e54348fc0104887143e";
    hash = "sha256-I0eBnZ/vnWDiL/BDYhVsdIQKXf/NIQg+jMkt7esBKRk=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      modDir = "bshift";

      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=bshift"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
})
