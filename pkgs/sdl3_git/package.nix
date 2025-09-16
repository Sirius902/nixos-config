{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-16";
  src = prevAttrs.src.override {
    tag = null;
    rev = "9ad04ff69e2868f2ad947365727f33ff74851802";
    hash = "sha256-vQSd/Yabs2bnfCgoHhuhtmJzKauvZGy/6kNVTGFBcPM=";
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
