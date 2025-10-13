{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-10-13";
  src = prevAttrs.src.override {
    tag = null;
    rev = "a4370093d5454bd5f85d03145a2a754c984bba9a";
    hash = "sha256-KbCIEV1AfKvsm9/zqSiz9k7ZWYva+ySbAPX10DJdNN8=";
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
