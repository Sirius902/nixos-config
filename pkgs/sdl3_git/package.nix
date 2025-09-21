{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-21";
  src = prevAttrs.src.override {
    tag = null;
    rev = "bae34c3e34f8e7180279a2e5b77c2c79910e4944";
    hash = "sha256-WL32pFibiG16jRilDD47QEFTxEiwCcrfZ9G7knCPWdc=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex"
          "release-(3\\..*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
