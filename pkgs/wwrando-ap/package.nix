{
  wwrando,
  fetchzip,
  fetchurl,
  imagemagick,
  libxcb,
  xkeyboard_config,
  nix-update-script,
}:
wwrando.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "wwrando-ap";
  version = "2.5.1";
  src = fetchzip {
    url = "https://github.com/tanjo3/wwrando/releases/download/ap_${finalAttrs.version}/wwrando_ap-${finalAttrs.version}-linux.zip";
    hash = "sha256-UZW/SPyKLiUnIgU07aAq42mtVx0OMFgz0kpRdY799S8=";
    stripRoot = false;
  };

  nativeBuildInputs =
    (prevAttrs.nativeBuildInputs or [])
    ++ [imagemagick];

  libraryPathDeps =
    (prevAttrs.libraryPathDeps or [])
    ++ [libxcb];

  inBin = "The Wind Waker Archipelago Randomizer";

  installIcon = let
    icon = fetchurl {
      url = "https://github.com/tanjo3/wwrando/raw/ap_${finalAttrs.version}/assets/icon.ico";
      hash = "sha256-2ShJMfyvqX7if43xbzgOMVJ7T/xaY6qbFZZNWABIr54=";
    };
  in ''
    mkdir -p $out/share/icons/hicolor
    frames=$(magick identify -format "%[scene] %[width] %[height]\n" ${icon})
    while read -r scene width height; do
      mkdir -p $out/share/icons/hicolor/''${width}x''${height}/apps
      magick "${icon}[$scene]" \
             $out/share/icons/hicolor/''${width}x''${height}/apps/${finalAttrs.pname}.png
    done <<< "$frames"
  '';

  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.pname} \
      --set XKB_CONFIG_ROOT "${xkeyboard_config}/share/X11/xkb"
  '';

  desktopItem = prevAttrs.desktopItem.override {
    desktopName = "Wind Waker Archipelago Randomizer";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version-regex"
          "ap_(.*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = "https://github.com/tanjo3/wwrando/releases/tag/${finalAttrs.version}";};
})
