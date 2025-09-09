{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-09";
  src = prevAttrs.src.override {
    tag = null;
    rev = "c5749f0ae7c8b6252dab321e78ab3b9d53deaba1";
    hash = "sha256-NX4rUgaZYE0nrnJn6wGdbMUyLY0VRulLXMd1XuOwbEw=";
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
