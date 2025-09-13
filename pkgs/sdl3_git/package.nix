{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-13";
  src = prevAttrs.src.override {
    tag = null;
    rev = "4561be89a5163aa393788be83bec99c7c49f6f27";
    hash = "sha256-BdyMRT0binPlpv4zkgnMjl/J2CphtyWii4W2SF+zPfU=";
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
