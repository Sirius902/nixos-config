final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "1.3.36";
    src = prevAttrs.src.override {
      hash = "sha256-Qur5AWl4Vx+It65DX+I+sc4lViz52OmXqvg+fL2t9I4=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      hash = "sha256-3H0GXxBI2OsiaJnPTtVFCzkQ17Qa2Mxfz5fI0SHK6kY=";
    };
  });
}
