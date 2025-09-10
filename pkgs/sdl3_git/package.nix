{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-10";
  src = prevAttrs.src.override {
    tag = null;
    rev = "e035f3a480529b0469fdfabcdc406b38f627bd86";
    hash = "sha256-3BNZH4Xvc7LOP9ToEZ0Q0iHfbmzQEVyxTzJdGK3RyX8=";
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
