# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0095b6d505fe45e7e09f980cbf48fff1800a9d79";
    hash = "sha256-LPHCFiabMHOokcQG6ZN5JFvlrBp5QTo1CC3PQu+FZRw=";
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
