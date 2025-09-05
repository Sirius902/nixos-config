final: prev:
prev.cosmic-session.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-05";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2441be2ad02fc28b397f67b704f2b41de7a96ed6";
    hash = "sha256-J+r4HoxZmKU0E8eirGpLOihIvkVlmkmcXMPMkWsQuK8=";
  };

  cargoHash = "sha256-bo46A7hS1U0cOsa/T4oMTKUTjxVCaGuFdN2qCjVHxhg=";

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
