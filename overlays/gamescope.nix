final: prev: {
  gamescope = prev.gamescope.overrideAttrs (prevAttrs: {
    version = "3.16.14.2-unstable-2025-08-29";
    src = prevAttrs.src.override {
      tag = null;
      rev = "2f30679c80791844c29402d232462874fe23dd46";
      hash = "sha256-6bFHcZ0diZbDJ3X/dDDBTbZXaZtw8gBg9gXb1BS5V2w=";
    };

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = final.nix-update-script {extraArgs = ["--version=branch"];};
      };
  });
}
