{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-09-26";

  src = prevAttrs.src.override {
    rev = "1cd7ae9a4e327f59994ea1fadd1e04814e1e0207";
    hash = "sha256-6F7hFjWY+MvAzkZOpzdqFPQvy9AwwH7+9p+S0JvO4lE=";
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
