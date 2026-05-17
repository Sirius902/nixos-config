final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.5.0-unstable-2026-05-17";
    src = prevAttrs.src.override {
      rev = "81c0fb818abf2b665f262e014f0387a1b73fdc34";
      tag = null;
      hash = "sha256-ULi+OP3QKCb4dpv+whJ/71ysnYDojFL8+oqcLheZFqM=";
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
