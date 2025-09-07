final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-07";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f3456ffc18d7f089a441f4b5fd77fe94943c665e";
    hash = "sha256-B39/WBoev3i/bTWq+VkStuJwUp8hZCnPzsrUyQCsDzA=";
  };

  cargoHash = "sha256-+d9c2VdJ+DT2H4zfV9znPlb1ZQZmh382Q/VTpjaT9ys=";

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
