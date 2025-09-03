{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-03";
  src = prevAttrs.src.override {
    tag = null;
    rev = "9abeeebad5b72a8f2cf94a02c01904ddbd68234a";
    hash = "sha256-K1nHjMqCQzRgX8Zj08IaLjz3UGCt3py6lS2E2D0GCYc=";
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
