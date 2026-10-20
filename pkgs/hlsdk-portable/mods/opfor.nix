{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-10-20";

  src = prevAttrs.src.override {
    rev = "54c48ed81445e21c02504466596d49f83530dc1f";
    hash = "sha256-CVcS2RI7NRGTFRnKsmHUSlIw7rVmyxlsluMRCD40kac=";
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
