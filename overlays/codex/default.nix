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
      version = "0.151.0";

      src = prevAttrs.src.override {
        tag = "rust-v${finalAttrs.version}";
        hash = "sha256-snrzA4W+vLqpPk3MS4xw9SszK1byCKo6ERz3JDgRZdA=";
      };

      cargoHash = "sha256-r6ox0dUH1OBkD8sQApfANrGbWxKXLv2UNLJZzciJc3I=";
      cargoDeps = prevAttrs.cargoDeps.overrideAttrs {
        vendorStaging = prevAttrs.cargoDeps.vendorStaging.overrideAttrs {
          outputHash = finalAttrs.cargoHash;
        };
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = ./update.sh;
        };

      meta =
        prevAttrs.meta
        // {
          changelog = "https://raw.githubusercontent.com/openai/codex/refs/tags/rust-v${finalAttrs.version}/CHANGELOG.md";
        };
    });
}
