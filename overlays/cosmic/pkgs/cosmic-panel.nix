# TODO(Sirius902) Overlay new cosmic-panel to avoid crashes when disconnecting displays
# until the nixos-unstable version is newer.
final: prev:
prev.cosmic-panel.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-27";

  src = prevAttrs.src.override {
    tag = null;
    rev = "efbc15c4c3c189d051c57f273162a5fc88a0e99a";
    hash = "sha256-TF1fUnN2pDmf7+GA4GLqncHODznnoubja/3stZbdBH4=";
  };

  cargoHash = "sha256-VlEbbQTAX05zJYURZym4bBhCtbQ85ujvqLMQNHSz23o=";

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
