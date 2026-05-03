final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.4.0-unstable-2026-05-01";
    src = prevAttrs.src.override {
      rev = "946d729a0a174fa928fef2d7e2b38a4e7cd7687c";
      tag = null;
      hash = "sha256-laaOma5KtSO13Ojppy8KBwmRebFZG2+VxmqXU+W/FT8=";
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
