{
  lib,
  stdenv,
  sdl3,
  zenity,
  waylandSupport ? stdenv.hostPlatform.isLinux && !stdenv.hostPlatform.isAndroid,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.24-unstable-2025-10-09";
  src = prevAttrs.src.override {
    tag = null;
    rev = "a6fc2c4b6098a51a5ec76719c61a23765d8f3eb8";
    hash = "sha256-iAIiOgTLyPLBAwstFBOkpuwHqvwRi+u29OR34q0+xYk=";
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

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex=release-(3\\..*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
