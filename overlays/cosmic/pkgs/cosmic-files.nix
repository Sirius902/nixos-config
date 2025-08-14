final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "b3a6d14bc63ebec6aae5ee5d20c12b967cecbbc5";
    hash = "sha256-CKsVnNgHhJBjAJU0kD/zBHd8WBMx2zbffxRYisnYY0k=";
  };

  cargoHash = "sha256-TDXo0PsDLIBewAasBK82VsG1O0lPqY6g3dBRFsGzF6A=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  # FUTURE(Sirius902) One of the tests is broken currently due to a missing arg. Re-enable once it is fixed.
  # https://github.com/pop-os/cosmic-files/blob/b3a6d14bc63ebec6aae5ee5d20c12b967cecbbc5/src/tab.rs#L6470
  doCheck = false;

  passthru.updateScript = final.nix-update-script {
    extraArgs = [
      "--version-regex"
      "epoch-(.*)"
    ];
  };
})
