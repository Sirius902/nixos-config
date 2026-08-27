final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.8.0-unstable-2026-08-25";
    src = prevAttrs.src.override {
      rev = "869bd590a6f695870b717b72d9397b9228cc104d";
      tag = null;
      hash = "sha256-17IF+E0ME/N6AlQRPySGUwEqjlE4qdF3i3ibeIHd8Q8=";
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
