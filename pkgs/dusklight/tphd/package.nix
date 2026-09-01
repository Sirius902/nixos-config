{
  dusklight,
  lib,
  nix-update-script,
  stdenv,
}:
(dusklight.override {
  symgenVersion = "1.3.2";
  symgenHashes = {
    darwin = "sha256-A0SDjRZ03wnBfD7t3PJuuJwzP9uF39ePaK3ENgcOzL4=";
    linux = "sha256-69YvuWI6zJQrYpVgniMG+FpzBDsKihF/IHK3Yd0I5o8=";
  };
  funchookVersion = null;
})
.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "dusklight-tphd";
  version = "0-unstable-2026-08-11";
  src = prevAttrs.src.override {
    rev = "d6e4d0b58deff9c20519060493e285c13a5f1887";
    hash = "sha256-wlL7KWkG2kuuGhZeoP36MpDGMJqYA8Z14ejzS0iOSCI=";
  };

  postPatch =
    (prevAttrs.postPatch or "")
    + ''
      # Store data under TwilitRealm/DusklightTPHD.
      substituteInPlace src/dusk/app_info.hpp \
        --replace-fail '.appName = "Dusklight"' '.appName = "DusklightTPHD"' \
        --replace-fail 'AppName = "Dusklight"' 'AppName = "DusklightTPHD"'
      substituteInPlace src/dusk/data.cpp \
        --replace-fail '.appName = "Dusk"}' '.appName = "DusklightTPHD"}'
    '';

  postInstall =
    (prevAttrs.postInstall or "")
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      mv $out/share/${finalAttrs.pname}/dusklight $out/share/${finalAttrs.pname}/dusklight-tphd
      rm $out/bin/dusklight
      ln -s $out/share/${finalAttrs.pname}/dusklight-tphd $out/bin/dusklight-tphd

      mv $out/share/applications/dev.twilitrealm.dusk.desktop \
       $out/share/applications/dev.twilitrealm.dusk-tphd.desktop

      for f in $out/share/icons/hicolor/*/apps/*dusk.png; do
        mv "$f" "''${f%dusk.png}dusk-tphd.png"
      done

      substituteInPlace $out/share/applications/dev.twilitrealm.dusk-tphd.desktop \
        --replace-fail "Exec=dusklight" "Exec=dusklight-tphd" \
        --replace-fail "''\nName=Dusklight''\n" "''\nName=Dusklight (TPHD)''\n" \
        --replace-fail "GenericName=Dusklight" "GenericName=Dusklight TPHD" \
        --replace-fail "Icon=dev.twilitrealm.dusk" "Icon=dev.twilitrealm.dusk-tphd"
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      mv $out/Applications/Dusklight.app $out/Applications/DusklightTPHD.app
    '';

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch=tphd"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };

  meta = prevAttrs.meta // {mainProgram = "dusklight-tphd";};
})
