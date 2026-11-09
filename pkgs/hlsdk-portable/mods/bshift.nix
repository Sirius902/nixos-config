{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-11-07";

  src = prevAttrs.src.override {
    rev = "d071f318e6271168efc330c8186f4e8bd5222418";
    hash = "sha256-+j4mWVSJ2JxBF88Ntj+tqvid+zg7nDxMAQkW+Z7nYO8=";
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
