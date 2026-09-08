{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-09-08";

  src = prevAttrs.src.override {
    rev = "fe56297222e138ccd681e7e235b91d39e065fde0";
    hash = "sha256-ZUPVwhi5koAoSwGDo4PaxWzLbKfksX0ddux1cIYFo4o=";
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
