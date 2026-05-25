{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-05-24";

  src = prevAttrs.src.override {
    rev = "c3133ccc8fc98e9e9e0df5226d2f5adbe8416574";
    hash = "sha256-6A7mPgUZPyuUd2F/rPWcoHLa6FmhnQunqNtWLOL7b3k=";
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
