final: prev:
prev.cosmic-applets.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-27";

  src = prevAttrs.src.override {
    tag = null;
    rev = "4dfb2025b60baa922933b62300f9da30c2a93eb8";
    hash = "sha256-b/X5dwZRJoML6DQDr5IJ9QEa0qKiPszm2N9Yc3GSgHE=";
  };

  cargoHash = "sha256-lL1nab0EuDbfcz9d8EBRKrGprDGGedXci+J6fNGqy8w=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  # FUTURE(Sirius902) Remove this if upstream removes the bluetooth spam patch (already applied here).
  patches = builtins.filter (p: p.name != "fix-bluetooth-dbus-spam.patch") (prevAttrs.patches or []);

  # FUTURE(Sirius902) cosmic-applets now depends on pipewire and libclang. Remove these if it is added upstream.
  nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [final.rustPlatform.bindgenHook];

  buildInputs = (prevAttrs.buildInputs or []) ++ [final.pipewire];

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
