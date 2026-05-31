{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-05-31";

  src = prevAttrs.src.override {
    rev = "0dcba6ac9a0ee5a8f9d50646765a59050f751e85";
    hash = "sha256-4/NZmvmqq2EaDizOTKk8FJw5SKIX2xziTgZ/b7C347Y=";
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
