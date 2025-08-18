final: prev:
prev.cosmic-applets.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2c618622d3f8d644776b669c96759f53324b275d";
    hash = "sha256-BSgrZAUzZ7XytbNsChEvXtAUOWZ/iHMySQFuULMotgY=";
  };

  cargoHash = "sha256-v4hlNZXmaX3kipbhFRo1gG7BjUIeumv1F0Z/8CYoSyc=";

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
