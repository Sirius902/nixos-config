final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.5.0-unstable-2026-05-13";
    src = prevAttrs.src.override {
      rev = "2db8e1ac40abf13298e81f093b40a460276b064c";
      tag = null;
      hash = "sha256-jSg8y1wkTLdzZscf3HgXCPoIBfg/aSmTOKdbbJvyfrM=";
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
