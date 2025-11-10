{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.58";
  src = prevAttrs.src.override {
    tag = null;
    rev = "release-2.32.58";
    hash = "sha256-Ngmr/KG5dQ1IDVafn2Jw/29hFCzPGKc9GOenT/4fsIM=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = ["--version-regex=release-(.*)"];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
