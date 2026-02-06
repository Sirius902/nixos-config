{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.64";
  src = prevAttrs.src.override {
    tag = null;
    rev = "release-2.32.64";
    hash = "sha256-1K+KW5cK3YgcZtrMqJ7VxKGsYnZR/fJmQtRZbWk2TGM=";
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
