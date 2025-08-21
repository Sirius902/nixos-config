# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-21";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f2813f0500c6af8cb1fd804c520d181607c17938";
    hash = "sha256-1+c9dTvSSAhm5kBqvtRjt1wdfos9ce0ASM32BRhFg64=";
  };

  cargoHash = "sha256-6IV1qjLTBs6L+yntIEhWT4xcb8slae/6F3WTRP8fDtU=";

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
