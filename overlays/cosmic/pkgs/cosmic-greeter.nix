final: prev:
prev.cosmic-greeter.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7317353a32f9ed831423819d620775d4bad1db2f";
    hash = "sha256-2MfbtEVTarhsHM3zjX1csHU/nPkxiZLT1F6bmNPrkBI=";
  };

  cargoHash = "sha256-X/tSofi4aNtA5MeWCy03Tnnz3AxIF8MCZ7ofeMSWNCc=";

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
