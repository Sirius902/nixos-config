final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-23";

  src = prevAttrs.src.override {
    tag = null;
    rev = "78df139dedb5d40ddf53821c0d469eca9564689a";
    hash = "sha256-Y3sxzHbykzdQqwkQgpiChsbDjxaJYjSWeRMYorD7MGc=";
  };

  cargoHash = "sha256-dHyUTV5txSLWEDE7Blplz8CBvyuUmYNNr1kbifujHKk=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = final.nix-update-script {
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
