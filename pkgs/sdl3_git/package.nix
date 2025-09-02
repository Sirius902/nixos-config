{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.20-unstable-2025-08-30";
  src = prevAttrs.src.override {
    tag = null;
    rev = "875653658abcb6091fa6a17bd4859fb66e8a1187";
    hash = "sha256-HZbF6FecxKCGtjiHZ3K1ExDq5jvaKj5cq0pBXh+Jf0I=";
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
