final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "1.3.33";
    src = prevAttrs.src.override {
      hash = "sha256-lQpl6ecQfQ7KzEIytH3k4hLtvq+KkTL+3IR2ZukdZWM=";
    };
    patches = [../patches/moonlight/disable_updates.patch];
    pnpmDeps = prevAttrs.pnpmDeps.override {
      hash = "sha256-PRlgwyePFpFdQRcojGDEC4ESZEGTJf1Ad9EFgm8hmKY=";
    };
  });
}
