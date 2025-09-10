final: prev:
prev.cosmic-applets.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-10";

  src = prevAttrs.src.override {
    tag = null;
    rev = "c54bf8e189636cc550941294c4904cbf33342ecd";
    hash = "sha256-W9vN2bNZn1OGIxuhhsOsDzKe44D/gpNXu3e8WxFPzk0=";
  };

  cargoHash = "sha256-LFdcr6LPgzE18vFXpy0111220cu0TPVNikAdlQ+6EIs=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
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
