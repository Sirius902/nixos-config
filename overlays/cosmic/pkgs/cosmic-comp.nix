# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-08";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7684cd1b2c480007cf8bce7f68206e0921c8e7fe";
    hash = "sha256-ZpR5R7zWMO6U1f5V8BsOZ8KUZs69bFhSZvbyfOuTdGc=";
  };

  cargoHash = "sha256-7y2ZQ7KYfsUj/jmXe8I4GrXcdQMry9yg+IvPnEt7BJU=";

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
