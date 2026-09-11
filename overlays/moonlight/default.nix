final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.9.0-unstable-2026-09-11";
    src = prevAttrs.src.override {
      rev = "d8c5b0743f44f5c424e7008e2cd0bffb19a0322a";
      tag = null;
      hash = "sha256-19fOP57CE0kO8CeI+Y38E0koX32JzMqL9O1yF6PPP9k=";
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
