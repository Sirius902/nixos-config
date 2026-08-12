final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.7.0-unstable-2026-08-12";
    src = prevAttrs.src.override {
      rev = "478320c0baaaa8e33277ffcc3e65e89bcea49e7c";
      tag = null;
      hash = "sha256-EYTi5kakfGJYBpVK9cNEMR4/Tq/npconZpKnoQ0/dNM=";
    };
    patches = [
      (final.fetchurl {
        name = "disable_updates.patch";
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/df14c8e0a9120b0702e89fed5b2c908de6e0b9f4/pkgs/by-name/mo/moonlight/disable_updates.patch";
        sha256 = "sha256-J2CCzLd9TEhdmEt3Zlh2cbKFx8kapROMpAEZVCcQjVg=";
      })
    ];
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
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
