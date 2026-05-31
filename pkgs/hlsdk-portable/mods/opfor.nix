{
  fetchpatch2,
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

  patches =
    (prevAttrs.patches or [])
    ++ [
      (fetchpatch2 {
        name = "wscript-disable-declaration-after-statement.patch";
        url = "https://github.com/FWGS/hlsdk-portable/commit/77e18273cb2890a549ae3d6ff8016b42abbc1509.patch?full_index=1";
        hash = "sha256-ZoRg0d4UewUR4im07hJpkeV2o31RXfKP23DnjxVjuZM=";
      })
    ];

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
