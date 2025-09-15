{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-15";
  src = prevAttrs.src.override {
    tag = null;
    rev = "08d84ea516adce4f2077f1b9cc3162c954ca542a";
    hash = "sha256-rV0ubn0X/BMUMogk1VbyQxNGZkpeZVyAQcqfHwXdCsY=";
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
