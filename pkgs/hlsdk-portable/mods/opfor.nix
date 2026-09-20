{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-09-20";

  src = prevAttrs.src.override {
    rev = "4515c64c6223e5f89d643b608047179efed1149f";
    hash = "sha256-X1aiAAvz/c2RyrHg8utRMFiZEgHhDIivM63yLCdk0bQ=";
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
