{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-20";
  src = prevAttrs.src.override {
    tag = null;
    rev = "9cefbab76699e8d4233e80d52e5db94581773257";
    hash = "sha256-I56RqWvA4MMgfb5uJcN5UhmxbUuIUyDF4+o23H8TWX8=";
  };

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
