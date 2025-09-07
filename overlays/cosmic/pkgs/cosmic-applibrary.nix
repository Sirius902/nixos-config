final: prev:
prev.cosmic-applibrary.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-07";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3c56c83d8c8f73865a10b9b21413921287bfcf25";
    hash = "sha256-UsE8OjVD7N/SIER2Ene8h28pK/it0Cr05A++aKR6lYk=";
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
