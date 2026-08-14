final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.7.0-unstable-2026-08-14";
    src = prevAttrs.src.override {
      rev = "b01fae2545664dcf2d910ccc32c94bf2e0288a36";
      tag = null;
      hash = "sha256-FQBbH3UUWy1dU/4Rj5g3HY0Z+9sBsu61WGX5nyDd2/0=";
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
