final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.3.3";
    src = prevAttrs.src.override {
      hash = "sha256-hGyUoAR0Pv6mkImRDlrnfYAucgJwg2phj6moxewf3aY=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-1jGEzTPPlwAFDKPbH92HvYg4rzFrUJLqhZRMNS+H6GI=";
    };
  });
}
