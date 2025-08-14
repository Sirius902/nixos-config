# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-14";

  src = prevAttrs.src.override {
    tag = null;
    rev = "e8f6d3cc03c1aff9e4adc42e1e51e047a1f5fbb6";
    hash = "sha256-0gbLYUeu7H9e5fgLrSVDyCQ2hDbDwIMVYUBQq8Z99LE=";
  };

  cargoHash = "sha256-XyiPpYVqk9y1V+0R0zIHXxLuao8qS8o8ZGTqp8+32PE=";

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
