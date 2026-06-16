final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.5.2-unstable-2026-06-16";
    src = prevAttrs.src.override {
      rev = "1594705b1e9b588b558f06cdd54fb0c04162a039";
      tag = null;
      hash = "sha256-9OAzVj9vR5Lqxc5axiafJl6dcxbpCCkVxoBgaIg8078=";
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
