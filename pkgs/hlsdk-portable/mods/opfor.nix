{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-05-31";

  src = prevAttrs.src.override {
    rev = "756e88fc30d643d18a021a89453a98d9bf04367c";
    hash = "sha256-VKGoQCHt7A5hrvL8qmis733CLbKnfVJz/SjkRpZ8NdE=";
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
