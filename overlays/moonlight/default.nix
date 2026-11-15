final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.10.1-unstable-2026-10-28";
    src = prevAttrs.src.override {
      rev = "649f96a05468a238c9f021021b4993036ca75b0f";
      tag = null;
      hash = "sha256-E51fkzzqe1nZt3S/9f0zJWEo5XKQ23A7Bllqrd/Cndc=";
    };
    patches =
      (prevAttrs.patches or [])
      ++ [
        # TODO(Sirius902) Drop once upstream moonlight has its own fixes for these.
        ../../patches/moonlight/fix-settings-entry-and-stale-finds.patch
      ];
    pnpmDeps = prevAttrs.pnpmDeps.override {
      hash = "sha256-g1wlpbUlGwE3Chrry89gJX2+3+jY/jyXYwiAWAfoHlA=";
    };

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = final.nix-update-script {
          extraArgs = [
            "--version=branch"
            "--version-regex=v(.*)"
          ];
        };
      };
  });
}
