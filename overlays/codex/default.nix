final: prev: let
  fetchers = final.callPackage ./fetchers.nix {};
  librusty_v8 = final.callPackage ./librusty_v8.nix {
    inherit (fetchers) fetchLibrustyV8;
  };
  librusty_v8_src_binding = final.callPackage ./librusty_v8_src_binding.nix {
    inherit (fetchers) fetchLibrustyV8SrcBinding;
  };
in {
  codex =
    (prev.codex.override {
      inherit librusty_v8 librusty_v8_src_binding;
    }).overrideAttrs (finalAttrs: prevAttrs: {
      version = "0.149.0";

      src = prevAttrs.src.override {
        tag = "rust-v${finalAttrs.version}";
        hash = "sha256-SMVTW/CcGz4xxyeFe3KUf3Ns6jp+2SRMTvtA2o2+y7Q=";
      };

      cargoHash = "sha256-K58PL588Hhk75FyXgU6b8IEAco8FIz8oGd1S0WgOjyQ=";
      cargoDeps = prevAttrs.cargoDeps.overrideAttrs {
        vendorStaging = prevAttrs.cargoDeps.vendorStaging.overrideAttrs {
          outputHash = finalAttrs.cargoHash;
        };
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final._experimental-update-script-combinators.sequence [
            (final.nix-update-script {
              extraArgs = [
                "--use-github-releases"
                "--version-regex"
                "^rust-v(\\d+\\.\\d+\\.\\d+)$"
              ];
            })
            ./update.sh
          ];
        };

      meta =
        prevAttrs.meta
        // {
          changelog = "https://raw.githubusercontent.com/openai/codex/refs/tags/rust-v${finalAttrs.version}/CHANGELOG.md";
        };
    });
}
