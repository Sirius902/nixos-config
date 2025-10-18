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
  version = "3.2.24-unstable-2025-10-18";
  src = prevAttrs.src.override {
    tag = null;
    rev = "cbcb145eb4d0b1a9ef2f57a837d42fef1f930b65";
    hash = "sha256-Ok4UsiS/hJ0un5kb7KD+vUmLgeyfeqEzcyZhU3DRBNI=";
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
