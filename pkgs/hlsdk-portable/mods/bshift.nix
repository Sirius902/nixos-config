{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-09-09";

  src = prevAttrs.src.override {
    rev = "390ea89b7c2b463708ab337c7a2a4cca6c762c41";
    hash = "sha256-aJkWPoEE3Cyu0MC2hf5dZH02RsjcH0caMhrzNRP4F2g=";
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
