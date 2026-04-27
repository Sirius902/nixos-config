final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.4.0";
    src = prevAttrs.src.override {
      hash = "sha256-jbIdFHPomN0zD2I6UoClofvSNVdOqpf0nM1s5pbn7ew=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-veZx/b+cvpcRh1xXO8Y34dJtY2cgncqVSYYywb85Geo=";
    };
  });
}
