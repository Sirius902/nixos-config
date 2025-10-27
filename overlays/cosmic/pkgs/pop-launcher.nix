final: prev:
prev.pop-launcher.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.2.7-unstable-2025-10-01";

  src = prevAttrs.src.override {
    tag = null;
    rev = "eead361cca44d8e19e988572462c49e26cf20427";
    hash = "sha256-Db3Lj1GuhoEP2iMwgEF8HnGAUkz0IIr3ZQWmNd1EaOY=";
  };

  cargoHash = "sha256-9gYfQQQd/W3QQFavbLiJVFQDs0dkZtHDm3xNXZPzhLc=";

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
      updateScript = final.nix-update-script {};
    };
})
