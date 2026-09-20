{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-09-20";

  src = prevAttrs.src.override {
    rev = "e907f4b89ad69c9289a3e3edda00bf731ae8dc51";
    hash = "sha256-+1xWbAdMLRNu91Wa+0fGdOKc9QaPxKpSp8aIpMpK8cQ=";
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
