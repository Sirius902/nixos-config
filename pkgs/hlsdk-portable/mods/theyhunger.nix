{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-11-07";

  src = prevAttrs.src.override {
    rev = "65c09e8c16a5a08eb5f33fb859f9bcfb9d476f86";
    hash = "sha256-K5km5kCKfmmxabZ3bhelncXaZ6ZA7o/1+vRv9w1jEyI=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      modDir = "Hunger";

      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=theyhunger"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
})
