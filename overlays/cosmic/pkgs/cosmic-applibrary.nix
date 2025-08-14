final: prev:
prev.cosmic-applibrary.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-01";

  src = prevAttrs.src.override {
    tag = null;
    rev = "efb4cce330c61578fff10b57ed04e225d2dca91c";
    hash = "sha256-XiYrch2vhBWik8WDhJRBZi3FlUYDZSZKYni0r/Wri2s=";
  };

  cargoHash = "sha256-Jw8XvrMMIGzioMxNUWXV+hfu6fGu0vpvS7dAmJwo7SU=";

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
