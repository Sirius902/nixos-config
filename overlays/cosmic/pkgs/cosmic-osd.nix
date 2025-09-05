final: prev:
prev.cosmic-osd.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-05";

  src = prevAttrs.src.override {
    tag = null;
    rev = "30b3b5fb6943fe0cbd5078342e59d7d917a228b8";
    hash = "sha256-hX/1+b5TcKsHaaHmHZ2oMbzB3vUGrNw5UPRWBC+uulc=";
  };

  cargoHash = "sha256-qiQ4VV1ML2EpfxEdE/A8b6mhtnr5y1/Dr9BvtFu0zgg=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  # No longer needed due to https://github.com/pop-os/cosmic-osd/commit/4970139d875f9b28ea72d431e07ca3650a200470.
  postPatch = null;

  # FUTURE(Sirius902) cosmic-osd now depends on pipewire and libclang. Remove these if it is added upstream.
  nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [final.rustPlatform.bindgenHook];

  buildInputs = (prevAttrs.buildInputs or []) ++ [final.pipewire];

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
