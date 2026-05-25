{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-05-24";

  src = prevAttrs.src.override {
    rev = "ef86094065379af6b7a1e917e7376031e269a778";
    hash = "sha256-Bretcw9EUz1Iz4d6NFxUh2s2yuV0x5ayhAAGEYWtgH8=";
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
