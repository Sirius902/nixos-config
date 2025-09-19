{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-19";
  src = prevAttrs.src.override {
    tag = null;
    rev = "ac82534375bea547bfd176525c696ca3f54ea8c0";
    hash = "sha256-x1WWLfvMUNAJBZokS9RdBwHZa9Bgo5g5mSisTB75GLE=";
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
