final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.3.1";
    src = prevAttrs.src.override {
      hash = "sha256-v4GAFP5cN9UXzqG+JVGlqnTQBKyXB2/cUXiOvleuFDE=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-1jGEzTPPlwAFDKPbH92HvYg4rzFrUJLqhZRMNS+H6GI=";
    };
  });
}
