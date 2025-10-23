{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-10-23";
  src = prevAttrs.src.override {
    tag = null;
    rev = "bbbab8660ae84022584757c35bdb8723632e6462";
    hash = "sha256-UkybIVB3NAxIR7aack0S9OAfKSfY5Yc7+6QROjCS9tU=";
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
