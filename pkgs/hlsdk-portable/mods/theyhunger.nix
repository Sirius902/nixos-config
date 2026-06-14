{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-06-14";

  src = prevAttrs.src.override {
    rev = "e57c82ed776f386f0814339c2a843d5c0149e4df";
    hash = "sha256-K+MeKZd76XBPCob0yvzb3hCPZn114S4z/j4cjdcc3qE=";
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
