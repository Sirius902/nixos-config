final: prev: {
  claude-code =
    (prev.claude-code.override {
      manifest = final.lib.importJSON ../../pkgs/claude-code/manifest.json;
    }).overrideAttrs (prevAttrs: {
      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = ../../pkgs/claude-code/update.sh;
        };
    });
}
