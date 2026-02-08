{
  xash-sdk,
  nix-update-script,
}:
xash-sdk.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2025-08-17";

  src = prevAttrs.src.override {
    rev = "790be1f135d601ffce1970ea1a7c8c5e49641d11";
    hash = "sha256-ViKOFVTQpBDRwn7BwHSuW9I+ai7ag+Vz1C2sGb7M/7I=";
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
