{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-06-14";

  src = prevAttrs.src.override {
    rev = "cd04b6190b234b27abc31dd992947af3842f6d24";
    hash = "sha256-t0gm4y3jdY+421w2Xyw7XkWA4UdkEbTxCJIU6o8Zsqg=";
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
