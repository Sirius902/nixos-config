final: prev: {
  gamescope = prev.gamescope.overrideAttrs (prevAttrs: {
    version = "3.16.17-unstable-2025-09-04";
    src = prevAttrs.src.override {
      tag = null;
      rev = "cf288b95fa376a15f30fe8d1a9f750cad54742df";
      hash = "sha256-eKAOlmU0wc1DViZkUSrPFVjypa/kGfe+1+0lkXbaVJI=";
    };

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = final.nix-update-script {extraArgs = ["--version=branch"];};
      };
  });
}
