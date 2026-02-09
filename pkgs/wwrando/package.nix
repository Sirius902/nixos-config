{
  lib,
  stdenv,
  stdenvNoCC,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  fetchzip,
  fetchurl,
  glib,
  libGL,
  libX11,
  libz,
  fontconfig,
  libxkbcommon,
  freetype,
  dbus,
  zlib,
  wayland,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "wwrando";
  version = "1.10.0";
  src = fetchzip {
    url = "https://github.com/LagoLunatic/wwrando/releases/download/${finalAttrs.version}/wwrando-${finalAttrs.version}-linux-x64.zip";
    hash = "sha256-WuTyukQVY3t3ZfwNZScLXfzPcOW6y5kNt7Z0XCJ8kZQ=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = finalAttrs.runtimeDependencies;

  runtimeDependencies = [libz];

  libraryPathDeps = [
    (lib.getLib stdenv.cc.cc)
    glib
    libGL
    fontconfig
    libX11
    libxkbcommon
    freetype
    dbus
    zlib
    wayland
  ];

  inBin = "Wind Waker Randomizer";

  installPhase = let
    outBin = "$out/bin/${finalAttrs.pname}";
  in ''
    runHook preInstall

    mkdir -p $out/bin
    cp "${finalAttrs.inBin}" "${outBin}"
    chmod +x "${outBin}"

    mkdir -p $out/lib
    cp -r models $out/lib
    cp README.txt $out/lib

    wrapProgram "${outBin}" \
      --run 'datadir="''${XDG_DATA_HOME:-$HOME/.local/share}/${finalAttrs.pname}"' \
      --run 'if [ ! -d "$datadir" ]; then
               mkdir -p "$datadir"
               cp -r "${placeholder "out"}/lib/"* "$datadir/"
               chmod -R u+w "$datadir"
             fi' \
      --run 'cd "$datadir"' \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.libraryPathDeps}"

    runHook installIcon

    runHook postInstall
  '';

  installIcon = let
    icon = fetchurl {
      url = "https://github.com/LagoLunatic/wwrando/raw/${finalAttrs.version}/assets/swift%20sail%20icon.png";
      hash = "sha256-xcxULqDN+uPnJj3utxHr2XPrr+6JVeMRZ4ifkWAPVKI=";
    };
  in ''
    install -Dm644 ${icon} \
      $out/share/icons/hicolor/48x48/apps/${finalAttrs.pname}.png
  '';

  desktopItem = makeDesktopItem {
    name = finalAttrs.pname;
    icon = finalAttrs.pname;
    desktopName = finalAttrs.inBin;
    categories = ["Game"];
    type = "Application";
    exec = finalAttrs.pname;
  };

  desktopItems = [finalAttrs.desktopItem];

  passthru.updateScript = nix-update-script {};

  meta = {
    # TODO(Sirius902) better description?
    description = "This is a randomizer for The Legend of Zelda: The Wind Waker.";
    homepage = "https://lagolunatic.github.io/wwrando";
    changelog = "https://github.com/LagoLunatic/wwrando/releases/tag/${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = finalAttrs.pname;
    maintainers = with lib.maintainers; [
      # sirius902
    ];
    # TODO(Sirius902) darwin support?
    platforms = lib.platforms.linux;
  };
})
