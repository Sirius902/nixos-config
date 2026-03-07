final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "2026.3.0";
    src = prevAttrs.src.override {
      hash = "sha256-Tuv0IFhvZzvmf29EWNtrb5Y6YOCn+lIBzXpt7lfLVS8=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      fetcherVersion = 3;
      hash = "sha256-1jGEzTPPlwAFDKPbH92HvYg4rzFrUJLqhZRMNS+H6GI=";
    };
  });
}
