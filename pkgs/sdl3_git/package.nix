{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-14";
  src = prevAttrs.src.override {
    tag = null;
    rev = "f8bace9b9b61d61fe407a11d786b6e9e91f7f4ef";
    hash = "sha256-PG+oCDZtEd2C8yb0QgE3mtCyQs2/PY6Kym5UAKKiCrc=";
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
