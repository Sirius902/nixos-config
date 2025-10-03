final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "1.3.32";
    src = prevAttrs.src.override {
      hash = "sha256-aXap/wUjjJTCy2eq7p7BL6ZYOVZEBVY4/YkrDtbIj2Q=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      hash = "sha256-gv+PHGbo0IiPgcxi0RAvsNmGLHWZar3SB4eW7NbJRJY=";
    };
  });
}
