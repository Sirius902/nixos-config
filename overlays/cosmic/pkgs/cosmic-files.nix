final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-17";

  src = prevAttrs.src.override {
    tag = null;
    rev = "16868ca990383c608f871107aef4e4bd75f74f34";
    hash = "sha256-C5KtH2TpIEapl4WhNb9QeVPamAlgGYa5c/TXqE2d5q4=";
  };

  cargoHash = "sha256-TDXo0PsDLIBewAasBK82VsG1O0lPqY6g3dBRFsGzF6A=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  # FUTURE(Sirius902) A few tests are broken currently due to `ThumbCfg` stuff. Re-enable once they are fixed.
  doCheck = false;

  passthru.updateScript = final.nix-update-script {
    extraArgs = [
      "--version-regex"
      "epoch-(.*)"
    ];
  };
})
