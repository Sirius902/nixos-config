final: prev: {
  gamescope = prev.gamescope.overrideAttrs (prevAttrs: {
    version = "3.16.14.2-unstable-2025-07-30";
    src = prevAttrs.src.override {
      tag = null;
      rev = "1faf7acd90f960b8e6c816bfea15f699b70527f9";
      hash = "sha256-/JMk1ZzcVDdgvTYC+HQL09CiFDmQYWcu6/uDNgYDfdM=";
    };

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = final.nix-update-script {extraArgs = ["--version=branch"];};
      };
  });
}
