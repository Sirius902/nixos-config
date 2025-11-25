final: prev:
prev.cosmic-workspaces-epoch.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-14";

  src = prevAttrs.src.override {
    tag = null;
    rev = "04edd3b9090cd0971f6b4f97fa34400bce7720e1";
    hash = "sha256-7iOiVrMHpE5oG/qIH0DIgBeHEEm0x7HIDLv64FFs300=";
  };

  cargoHash = "sha256-7BdyHz66A+QhJY0haohaQiNkhpmX9rqIW9gD8E4Q7Qg=";

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
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
