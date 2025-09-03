final: prev: {
  gamescope = prev.gamescope.overrideAttrs (prevAttrs: {
    version = "3.16.16-unstable-2025-09-03";
    src = prevAttrs.src.override {
      tag = null;
      rev = "a51480365788b819030cc8dc6a08566a56da10de";
      hash = "sha256-HxdcB0dbvHV+TBqnseZPlLQ2vI0DS5VI17ROeaSjAPU=";
    };

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = final.nix-update-script {extraArgs = ["--version=branch"];};
      };
  });
}
