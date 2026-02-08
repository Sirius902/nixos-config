final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.2.0";
    src = prevAttrs.src.override {
      hash = "sha256-VqO3pUqnKP2VE1I/HtuY6bF/k/ijh5CBeE35Mpp6rGo=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-mSuk829qkNq+dDDympXCBzqMUJc4L9zqzcmVZwfbXsE=";
    };
  });
}
