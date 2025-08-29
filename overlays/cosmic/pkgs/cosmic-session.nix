final: prev:
prev.cosmic-session.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-29";

  src = prevAttrs.src.override {
    tag = null;
    rev = "4598b7cdf4a2d41737d68415966a475759d34d55";
    hash = "sha256-S5pSlbnif2i8HNAXrYY5t+Jzi1ndJNNPVRXitHI+zMU=";
  };

  cargoHash = "sha256-bo46A7hS1U0cOsa/T4oMTKUTjxVCaGuFdN2qCjVHxhg=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  # See https://github.com/pop-os/cosmic-session/commit/4598b7cdf4a2d41737d68415966a475759d34d55.
  postPatch =
    (prevAttrs.postPatch or "")
    + ''
      substituteInPlace data/start-cosmic \
        --replace-fail '/usr/bin/gnome-keyring-daemon' "${final.gnome-keyring}/bin/gnome-keyring-daemon"
    '';

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
