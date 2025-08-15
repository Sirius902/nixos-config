# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "4209e61c48f424f9c7949c69cbef81799b1ec8ad";
    hash = "sha256-qNtXaRhn7wVkd743Fk0IQfTslviA+HX1n7Ciq7Wi1Uk=";
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
