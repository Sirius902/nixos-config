{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-09-13";

  src = prevAttrs.src.override {
    rev = "47dd234216ad8400ff3d2cfd20cab19b40dc6503";
    hash = "sha256-waa47MLN+9Th066yg0qe+L4igClYASG7wHHslZionOs=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      modDir = "gearbox";

      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=opfor"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
})
