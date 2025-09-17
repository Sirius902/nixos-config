{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-17";
  src = prevAttrs.src.override {
    tag = null;
    rev = "5dfa2cb88a43f9241a3069430de6d007ccb8f233";
    hash = "sha256-ZTBTy+2Rdt2qpxXBpVrXlORUFYnqnIfsg2AdobtM0Ek=";
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
