{
  SDL2,
  sdl3_git,
  nix-update-script,
  ...
}:
(SDL2.override {sdl3 = sdl3_git;}).overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "2.32.56-unstable-2025-09-16";
  src = prevAttrs.src.override {
    tag = null;
    rev = "3a6d7d244abb900037fb8715f5a4d63cbebf2beb";
    hash = "sha256-AKs61nusjLtTUdbzYBeZxF/aBhdd5oQ3/8GAuwLfg1g=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex"
          "release-(.*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
