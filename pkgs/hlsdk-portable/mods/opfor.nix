{
  hlsdk-portable,
  nix-update-script,
}:
hlsdk-portable.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-opfor";
  version = "0-unstable-2026-06-14";

  src = prevAttrs.src.override {
    rev = "613eb55d5bcd257219c881297d1d43c1da4a7445";
    hash = "sha256-sMOlK3KeZzYNQstLeYOd2TND4ikd9M+3yAKVKOKE2tI=";
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
