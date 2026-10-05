{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-theyhunger";
  version = "0-unstable-2026-10-04";

  src = prevAttrs.src.override {
    rev = "0c26ff78618d7e0c448aade75175599cf8dc14df";
    hash = "sha256-SKXaBCZKCe6yFTRVUzU+GwC0rSfkt89jqOWXhdi5zfA=";
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
