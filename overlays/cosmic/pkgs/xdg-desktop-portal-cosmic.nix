# TODO(Sirius902) Overlay new xdg-desktop-portal-cosmic to maybe fix clipboard shenanigans
# until the nixos-unstable version is newer.
final: prev:
prev.xdg-desktop-portal-cosmic.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7e803d13e3b4d28f2954a628675dcc2be4f3765c";
    hash = "sha256-rxUVVvNlb3IjVfCeIIKzDecN1TDZ2WdmxVwdTngXMAI=";
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
