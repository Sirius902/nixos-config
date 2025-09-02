# TODO(Sirius902) Overlay new xdg-desktop-portal-cosmic to maybe fix clipboard shenanigans
# until the nixos-unstable version is newer.
final: prev:
prev.xdg-desktop-portal-cosmic.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-02";

  src = prevAttrs.src.override {
    tag = null;
    rev = "de1f131344a5de6bccaf3481e977b7d7e322aea9";
    hash = "sha256-cvb+GrRUbK48RqKi5PW8mMv5XKLuPexgffxw+vkQr8A=";
  };

  cargoHash = "sha256-NQoqbfNEMWowo2KxdgKqTbn/BDgv218NFCCGYR9OAO0=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = final.nix-update-script {
        extraArgs = [
          "--version-regex"
          "epoch-(.*)"
        ];
      };
    };
})
