{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-11-07";

  src = prevAttrs.src.override {
    rev = "7d618678a9c9e5c398c3c4039a4702576a86a6e6";
    hash = "sha256-ndEJVmv4L3Lz/D6xeBsDo9xcCiFs8FH3pryuXPqMwDE=";
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
