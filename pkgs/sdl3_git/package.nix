{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-11";
  src = prevAttrs.src.override {
    tag = null;
    rev = "8d5b82be2e77000b440d09ef8facca97b6c57582";
    hash = "sha256-j2Rp+Aal7VS9fp3HnP8QVYc3Oh3tim9fFJ33eilxF+g=";
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
