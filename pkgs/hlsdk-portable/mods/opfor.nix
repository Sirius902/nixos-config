{
  fetchpatch2,
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-05-24";

  src = prevAttrs.src.override {
    rev = "c3133ccc8fc98e9e9e0df5226d2f5adbe8416574";
    hash = "sha256-6A7mPgUZPyuUd2F/rPWcoHLa6FmhnQunqNtWLOL7b3k=";
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
