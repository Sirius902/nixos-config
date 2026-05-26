{
  fetchpatch2,
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-05-24";

  src = prevAttrs.src.override {
    rev = "36022819fa351e49ece2e853107e0ceba9229b48";
    hash = "sha256-n9ZCZV2sSEw2zI3rFj90yygDO842Sc7WyqI7eYfQ2rg=";
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
      modDir = "Hunger";

      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=theyhunger"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
})
