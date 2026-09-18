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
      version = "0.155.1";

      src = prevAttrs.src.override {
        tag = "rust-v${finalAttrs.version}";
        hash = "sha256-iFW66odceRNBsVG5bD9SdcQGxhpm/QIZwYjGCrfMXiI=";
      };

      cargoHash = "sha256-6IAX/SFSSgSKKFxKsUXoZ9nNQaHJ+EjZ5a4bJwyDdF0=";
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
