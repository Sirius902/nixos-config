final: prev: {
  claude-code =
    (prev.claude-code.override {
      manifest = final.lib.importJSON ./manifest.json;
    }).overrideAttrs (prevAttrs: {
      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = ./update.sh;
        };
    });
}
