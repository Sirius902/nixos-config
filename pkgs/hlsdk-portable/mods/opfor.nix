{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-09-08";

  src = prevAttrs.src.override {
    rev = "e28121c3a4a670e12367dd59b48a3e4d8e621050";
    hash = "sha256-7r3ZcAVltAJ8HK9oFd8DWdWWXLAsG5QSgdYj/hkuNi8=";
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
