final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-11";

  src = prevAttrs.src.override {
    tag = null;
    rev = "6d9cd3e7e59102cd3f9d53f1326a23d1db5dbac7";
    hash = "sha256-+h3YbDqwprcftSdSBYnbNx6eusx5Im8W53/IOrBgEtk=";
  };

  cargoHash = "sha256-ujdlHtbb1N4V6Qp0KW+GGM+DglA5LQyAFnZ8u38cbMg=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  passthru.updateScript = final.nix-update-script {
    extraArgs = [
      "--version-regex"
      "epoch-(.*)"
    ];
  };
})
