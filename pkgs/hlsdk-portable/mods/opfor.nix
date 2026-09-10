{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-09-09";

  src = prevAttrs.src.override {
    rev = "bd0ca19013c2bb7a7c2651ae03031f2246c648bf";
    hash = "sha256-uQs0FPun+2Aa4gXgfz4tF8Q5a1UAFyj8Xc8iUSZ4FtY=";
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
