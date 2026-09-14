{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-09-13";

  src = prevAttrs.src.override {
    rev = "fe7cd20c6fa6fd00474264fb3d542cfda97b88fc";
    hash = "sha256-uKMPURebi6qcLghDm/yzyee4w8/10arMSwObeYun/q0=";
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
