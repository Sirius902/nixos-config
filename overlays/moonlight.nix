final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "1.3.29";
    src = prevAttrs.src.override {
      hash = "sha256-HlSyg/ccr1AKwui1lx7aLK3ocOPGaiTVVHDB1xL+wWQ=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      hash = "sha256-wbNAZmOqt1d243pIVM2tVdFD7BNpvPFVY3sxlYXoZCI=";
    };
  });
}
