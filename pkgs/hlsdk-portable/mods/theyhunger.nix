{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-09-09";

  src = prevAttrs.src.override {
    rev = "7fb322677d09cdcd95d98c5914919d9ce7ea80c6";
    hash = "sha256-xsZ6ndKQVA0imPShAYGNPUir9OYwZv0WGxYJxW40gxQ=";
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
