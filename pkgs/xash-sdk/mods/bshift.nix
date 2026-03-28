{
  xash-sdk,
  nix-update-script,
}:
xash-sdk.overrideAttrs (prevAttrs: {
  pname = prevAttrs.pname + "-bshift";
  version = "0-unstable-2026-03-26";

  src = prevAttrs.src.override {
    rev = "df5c27283d4c7409f54aa63bf15143e5598ce02d";
    hash = "sha256-PqlzwY7z8R8uRZdCtQ6XK+sN6bnbrsX/K8uXBHonPb8=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      modDir = "bshift";

      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=bshift"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
})
