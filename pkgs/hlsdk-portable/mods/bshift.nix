{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-05-31";

  src = prevAttrs.src.override {
    rev = "1df682bbdb605fb99e2301898ac317f8a1517ddd";
    hash = "sha256-q2tcuQZ7Q2GqTK3bULAB3hLxLIiWydrEMwECIdAjAXQ=";
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
