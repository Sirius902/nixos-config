final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.5.0-unstable-2026-05-04";
    src = prevAttrs.src.override {
      rev = "d40e9bafd47cf71cecfdb51e3f24d89a6a8ca5c2";
      tag = null;
      hash = "sha256-/3NQbdLThnPSjOZWNrtPGQpu7UZDisdDk4jGa+uSZcI=";
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
      hash = "sha256-veZx/b+cvpcRh1xXO8Y34dJtY2cgncqVSYYywb85Geo=";
    };

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = final.nix-update-script {
          extraArgs = [
            "--version=branch"
          ];
        };
      };
  });
}
