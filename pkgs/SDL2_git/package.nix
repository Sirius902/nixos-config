{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.58-unstable-2025-11-03";
  src = prevAttrs.src.override {
    tag = null;
    rev = "0d1ebe082a9c5d688d504fe8a9e6a07096855d15";
    hash = "sha256-pDs8JNKopcFcgFVD4GK19GaX51eneYk2rLJhBSrFlNA=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex=release-(.*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
