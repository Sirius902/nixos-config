{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-09-26";

  src = prevAttrs.src.override {
    rev = "172aec83418318a4190c0fa5e604057386fb8fa3";
    hash = "sha256-QPVlwkFnij7sZEMMuMUfBRHKjSTMZEg7AXaccIa0RaE=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      modDir = "gearbox";

      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=opfor"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
})
