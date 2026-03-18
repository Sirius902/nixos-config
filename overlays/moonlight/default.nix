final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.3.2";
    src = prevAttrs.src.override {
      hash = "sha256-VcYHwjm5RUfvkABts5ZP+qqqxBHyiF6JwTcBBG+xABA=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-1jGEzTPPlwAFDKPbH92HvYg4rzFrUJLqhZRMNS+H6GI=";
    };
  });
}
