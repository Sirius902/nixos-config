# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2ccdb6c93d50a727fc8b00f3010b417048dbbffa";
    hash = "sha256-hj5gYpLdZWkRH0tvgZMgJBMNIteZ/tg/WKvTxKLpltw=";
  };

  cargoHash = "sha256-wGq7Cdq56Hnzww+IVXCtZet4Zojj8VUmmsjsg53XHe8=";

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
