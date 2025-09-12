final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "1.3.28";
    src = prevAttrs.src.override {
      hash = "sha256-aLjHKVWkb9XHyoMmDBxLG2Ycg4CJFeieLdEg3CWeIwk=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      hash = "sha256-DvSBiUkIQbDkdgfHBw9h1odo3ApZq+emBDkbcQnx6NA=";
    };
  });
}
