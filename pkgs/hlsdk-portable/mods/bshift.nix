{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-10-04";

  src = prevAttrs.src.override {
    rev = "701bcef1a0ebac49e93ecff9e2c7724ff0b4278d";
    hash = "sha256-vlWlYvwY/kAsravFRHOM0a/aZ/d5dkPtYcQDD3aKUO4=";
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
