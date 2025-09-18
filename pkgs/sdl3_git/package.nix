{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-18";
  src = prevAttrs.src.override {
    tag = null;
    rev = "447df411e6683991081961213c3ae9f43dd710a2";
    hash = "sha256-X4Em0LQxMVd5tvcJKi9JCPG+4E4f1iauBhjfxVS6+Bg=";
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
