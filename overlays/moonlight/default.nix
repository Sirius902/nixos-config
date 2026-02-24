final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.2.2";
    src = prevAttrs.src.override {
      hash = "sha256-wZEpoUlDEbObXD5d2uA5vNBRrFOw4A6VLAc/MVNC4EE=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-1jGEzTPPlwAFDKPbH92HvYg4rzFrUJLqhZRMNS+H6GI=";
    };
  });
}
