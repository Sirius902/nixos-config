final: prev: {
  gamescope = prev.gamescope.overrideAttrs (prevAttrs: {
    version = "3.16.14.2-unstable-2025-08-28";
    src = prevAttrs.src.override {
      tag = null;
      rev = "9d9d442ddf58be8b171cd9a28aa523783b9175bb";
      hash = "sha256-2J1FIwFjiL/r5dVVYFD8H1qEBjmrlRZ1OKUv5oxCwsQ=";
    };

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = final.nix-update-script {extraArgs = ["--version=branch"];};
      };
  });
}
