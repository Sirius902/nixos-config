# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "4a385d55354f3b3ca3a994d24d165e127dad8179";
    hash = "sha256-66SYK0GjKpi/vCa3+Bhqq5jgm10SjwqZax3Fjv0/JpM=";
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
