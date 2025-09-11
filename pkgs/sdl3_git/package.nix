{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-10";
  src = prevAttrs.src.override {
    tag = null;
    rev = "4efdfd92a24ff3bbe6780666189000bf5d84ed30";
    hash = "sha256-qqbwQvrjcjl2ogWkoA/z5+Ib+zGlAKWLdr/Yl/BzjhQ=";
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
