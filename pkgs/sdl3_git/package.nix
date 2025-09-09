{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-08";
  src = prevAttrs.src.override {
    tag = null;
    rev = "11411bb5ef0658fc5e17b3459b722b5510a4cd89";
    hash = "sha256-4uJwz3wha0ZLfZFtOo62tkYTUe+fWY81Jwe+lLTNdUo=";
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
