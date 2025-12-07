{
  lib,
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.60";
  src = prevAttrs.src.override {
    tag = null;
    rev = "release-2.32.60";
    hash = "sha256-8nhSyifEeYEZj9tqid1x67jhxqmrR61NwQ/g0Z8vbw8=";
  };

  # Remove already applied patch.
  patches = lib.remove (lib.elemAt prevAttrs.patches 1) prevAttrs.patches;

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = ["--version-regex=release-(.*)"];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
