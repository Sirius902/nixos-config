final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "be67fd8e0dd0a6457c992a659e7d6884b343520f";
    hash = "sha256-JpJyCtavDo1KsARlGAZPnJIPXVRUZzM0tZ0etKECCvk=";
  };

  cargoHash = "sha256-TDXo0PsDLIBewAasBK82VsG1O0lPqY6g3dBRFsGzF6A=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  # FUTURE(Sirius902) One of the tests is broken currently due to a missing arg. Re-enable once it is fixed.
  # https://github.com/pop-os/cosmic-files/blob/be67fd8e0dd0a6457c992a659e7d6884b343520f/src/tab.rs#L6470
  doCheck = false;

  passthru.updateScript = final.nix-update-script {
    extraArgs = [
      "--version-regex"
      "epoch-(.*)"
    ];
  };
})
