{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-02";
  src = prevAttrs.src.override {
    tag = null;
    rev = "af74b1fe84911ef6e3f4739c1de8a442d77bd9d3";
    hash = "sha256-8toGbm8GWqZ6OFnuTet43t0IDDYH+piEVUSbjDar6pE=";
  };

  # TODO(Sirius902) NSO GC left stick calibration was broken by this commit.
  # https://github.com/libsdl-org/SDL/commit/1f007ad5cd6f8103e8975295e6cfa9659a26cad9
  patches = (prevAttrs.patches or []) ++ [./revert-ns2-led.patch];

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex"
          "release-(3\\..*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
