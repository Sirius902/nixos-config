final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "1.3.35";
    src = prevAttrs.src.override {
      hash = "sha256-/ROTBj7ZJP6n7MJXhHPkeSo9FlVkyo45958yiO6duvc=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      hash = "sha256-KD7dfJP+aRkJ8U/lyY653KDzLQ/qCWew+sNaU10tvDc=";
    };
  });
}
