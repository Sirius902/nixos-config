{
  dusklight,
  lib,
  nix-update-script,
  stdenv,
}:
dusklight.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "dusklight-tphd";
  version = "0-unstable-2026-07-12";
  src = prevAttrs.src.override {
    rev = "6bab72092bc0f341067e761a0fe4bc582c00ee59";
    hash = "sha256-38+3MPFAuTTxCuPMwq7oDBm+8hcXAQyCwcuAA8+w9qc=";
  };

  postPatch =
    (prevAttrs.postPatch or "")
    + ''
      # Store data under TwilitRealm/DusklightTPHD.
      substituteInPlace include/dusk/app_info.hpp \
        --replace-fail 'AppName = "Dusklight"' 'AppName = "DusklightTPHD"' \
        --replace-fail 'LegacyAppName = "Dusk"' 'LegacyAppName = "DusklightTPHD"'
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
        --replace-fail "''\nName=Dusklight''\n" "''\nName=Dusklight TPHD''\n" \
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
