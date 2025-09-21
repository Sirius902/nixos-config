final: prev:
prev.cosmic-ext-tweaks.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.1.3-unstable-2025-09-21";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0abd94eb76b6018bee9adddb345a55745d659af4";
    hash = "sha256-JWWKjaIxaq2XCOzht2Nl5oErG6D3xcJSYXlgSy0S42s=";
  };

  cargoHash = "sha256-ZFaL6qEKzSGZzOtcJX32wti0ivdA7CbYGREPFWZvxmc=";

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
