{
  xash-sdk,
  nix-update-script,
}:
xash-sdk.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2025-08-17";

  src = prevAttrs.src.override {
    rev = "8cffc250212a316a4d6ba94ac0b5ce9a7470fbbd";
    hash = "sha256-iSQJJvuZ2kII7MH7rnxp7Ry07my9lMe5R8NMv1oYxGQ=";
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
