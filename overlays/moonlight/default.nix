final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.2.1";
    src = prevAttrs.src.override {
      hash = "sha256-BpTN9AdQEDD2XnEUsUxgkoq+EPGhtnYgJhLKF4GVZoc=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-b3d8VcfQjCkcJThebXJ2yvKZfU8u4QnpZgNyqP6XIu0=";
    };
  });
}
