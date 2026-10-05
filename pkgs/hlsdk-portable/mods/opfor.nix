{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-10-04";

  src = prevAttrs.src.override {
    rev = "109b4821281c0e62e20fa23b96589fca2ec78ca0";
    hash = "sha256-thv5DILsswgEua09G8hhQJklYUjqLX2gI74Dcy2Qymk=";
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
