{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-09-09";

  src = prevAttrs.src.override {
    rev = "04744125429bca059f32e29f748b2df891ddf8c8";
    hash = "sha256-qGWJScWcJDLEhZJ6AOGZWuJ9JGnYdzJXrl+LCAXH/M0=";
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
