{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-10-31";

  src = prevAttrs.src.override {
    rev = "a137bb1a3d0a8f94d8598c42cc08aac506027cac";
    hash = "sha256-KW7knXGBDuG2AzMjXlw2fFpQA/WJHZQRQiTnyifgHDE=";
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
