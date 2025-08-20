final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-20";

  src = prevAttrs.src.override {
    tag = null;
    rev = "a76f7f86853a23d16ab4cc0bd53f701ff34b742e";
    hash = "sha256-SYwGIk5pHoVDNQa1ObkCyyWiZFpGrSST8DV3sNp5xBo=";
  };

  cargoHash = "sha256-TDXo0PsDLIBewAasBK82VsG1O0lPqY6g3dBRFsGzF6A=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  passthru.updateScript = final.nix-update-script {
    extraArgs = [
      "--version-regex"
      "epoch-(.*)"
    ];
  };
})
