{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-12";
  src = prevAttrs.src.override {
    tag = null;
    rev = "1c784c453dd0e5efe4b879c757eaa882ba0de6a4";
    hash = "sha256-BNWyPJ+jj73C0LOn3WsCZZFAGSee4cJhribkkSr7KEQ=";
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
