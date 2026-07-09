final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.5.2-unstable-2026-07-09";
    src = prevAttrs.src.override {
      rev = "5b0b9db0e4eee8400cf4d54a9c8d7fb1d439024f";
      tag = null;
      hash = "sha256-rzgB/dGUI/6Rdi2prCbt2uFC0Bh6dm0lufHhB9FPsEA=";
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
      hash = "sha256-+jxp3dD/SyGdskMyw0jhDzDRj7wXD4Egkx3ok3cMiyc=";
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
