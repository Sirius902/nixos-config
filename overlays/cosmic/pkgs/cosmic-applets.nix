final: prev:
prev.cosmic-applets.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-05";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7fdba2f9333fd44355181a0d0cd9b69b787ff81a";
    hash = "sha256-Eq0B82o+1HU1K52yzcFD5UtY3aPZbSUduMXG+fzvGb8=";
  };

  cargoHash = "sha256-KfsUAwte+U6hsXZS0N1Ywjw4sUpq0wkR9/nTalmv44c=";

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
