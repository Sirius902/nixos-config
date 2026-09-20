{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-09-20";

  src = prevAttrs.src.override {
    rev = "83c50c80e44dd81ee25102ea9a9af036be1399ad";
    hash = "sha256-i1l2mlHtfJupnGfLjZDYS7v7ib64pmKpByHFAcrDQ7c=";
  };

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
