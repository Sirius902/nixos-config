final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "1.3.39";
    src = prevAttrs.src.override {
      hash = "sha256-85W5OrP9Ju4ZJRUEZLpBreKxgUrHgxxZEv7KzcpqNDo=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-+wGup5wJIqTzkr4mTo/CxofffQmUz3JD2s/s/oY0viM=";
    };
  });
}
