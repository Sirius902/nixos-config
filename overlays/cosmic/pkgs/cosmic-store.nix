final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-11";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0c42853fa8cc9daa35b0bd85af6685f316362626";
    hash = "sha256-bS4ExEF2z54V5eAQyiZgvuPJ6KSvYZXyi9pQKR2qTrE=";
  };

  cargoHash = "sha256-55XHzkmH+Jerog3+Ltz1IO281JEdTEL+1vdfnoCZ31Y=";

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
        extraArgs = [
          "--version-regex"
          "epoch-(.*)"
        ];
      };
    };
})
