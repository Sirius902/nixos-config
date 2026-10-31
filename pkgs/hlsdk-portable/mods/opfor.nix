{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-10-31";

  src = prevAttrs.src.override {
    rev = "0a58cc581f529eebab6f4fa9a2d9513572642446";
    hash = "sha256-rUR1QwOwwDNlVl9HhXOptN2UFzVW9anX8uEfiR+7mqQ=";
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
