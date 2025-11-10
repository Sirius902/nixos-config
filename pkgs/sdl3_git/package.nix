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
  version = "3.2.26-unstable-2025-10-23";
  src = prevAttrs.src.override {
    tag = null;
    rev = "b31c4b70b3031dc4eb873612d65595a31b439a30";
    hash = "sha256-4/scd/wiFrKePUpKgSY5cfmxa7PdH2yfE7wh4ElYn98=";
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
          "--version=branch=preview-3.3.2"
          "--version-regex=release-(3\\..*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
