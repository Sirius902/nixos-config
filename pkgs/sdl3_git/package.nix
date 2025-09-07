{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-07";
  src = prevAttrs.src.override {
    tag = null;
    rev = "834b5ba7fb09a5d04236b78e09a3e31aa59e584c";
    hash = "sha256-SVlthbIoFCKmZn93d92i3jdefY4e2aQVycnbqLuacuc=";
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
