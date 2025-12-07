{
  lib,
  stdenv,
  sdl3,
  xorg,
  zenity,
  waylandSupport ? stdenv.hostPlatform.isLinux && !stdenv.hostPlatform.isAndroid,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.28-unstable-2025-12-06";
  src = prevAttrs.src.override {
    tag = null;
    rev = "f173fd28f04cb64ae054d6a97edb5d33925f539b";
    hash = "sha256-UnuqagY+Q1lQ9dhLYqEr1BrGTWg6oyKjm9Chg0SDxko=";
  };

  postPatch =
    # Tests timeout on Darwin
    # `testtray` loads assets from a relative path, which we are patching to be absolute
    lib.optionalString (finalAttrs.finalPackage.doCheck) ''
      substituteInPlace test/CMakeLists.txt \
        --replace-fail 'set(noninteractive_timeout 10)' 'set(noninteractive_timeout 30)'
    ''
    + lib.optionalString waylandSupport ''
      substituteInPlace src/dialog/unix/SDL_zenitymessagebox.c \
        --replace-fail '"zenity"' '"${lib.getExe zenity}"'
      substituteInPlace src/dialog/unix/SDL_zenitydialog.c \
        --replace-fail '"zenity"' '"${lib.getExe zenity}"'
    '';

  buildInputs = (prevAttrs.buildInputs or []) ++ [xorg.libXtst];

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=prerelease-3.3.4"
          "--version-regex=release-(3\\..*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
