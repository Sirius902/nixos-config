final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "1.3.37";
    src = prevAttrs.src.override {
      hash = "sha256-4cz1icY7i8RFdh/HhG/y6UzR/zkhsp4+G2dplm4g+wo=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-sU0EBSNwpjqyBsvyJim8Qz90dht7xc6f52HaY0sBPds=";
    };
  });
}
