{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.58-unstable-2025-11-04";
  src = prevAttrs.src.override {
    tag = null;
    rev = "da86b665aeb8b2b468c6a56df7c92be175974ee1";
    hash = "sha256-qRXHdMRFcXmhvb0QHCX32LCsJ/kpJXOekr5v5An9smQ=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex=release-(.*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
