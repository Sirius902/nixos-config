final: prev:
prev.cosmic-greeter.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-29";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f150f9e54e7646772dd2562695c07ade73587222";
    hash = "sha256-v2/RV6FyWdQX4uIrnhWFl0i9XNomwWLOdpuII2fnV5E=";
  };

  cargoHash = "sha256-J0Yj9povzqRVSdyRYp5wOyyDxP7GQP6QQ46mckuNNwU=";

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
