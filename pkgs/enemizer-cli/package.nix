{
  lib,
  stdenv,
  fetchurl,
  p7zip,
  jq,
  autoPatchelfHook,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "enemizer-cli";
  version = "7.1";

  src = fetchurl {
    url = "https://github.com/Ijwu/Enemizer/releases/download/${finalAttrs.version}/ubuntu.16.04-x64.7z";
    hash = "sha256-ZbQWji8M/JyCysBBV1jvXRtk7ekyc0fGi/KpIKXKfTM=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    jq
    p7zip
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];

  autoPatchelfIgnoreMissingDeps = [
    "liblttng-ust.so.0"
    "libcrypto.so.1.0.0"
    "libssl.so.1.0.0"
  ];

  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack
    7z x -osource $src
    runHook postUnpack
  '';

  sourceRoot = "source";

  postPatch = ''
    jq '.runtimeOptions.configProperties."System.Globalization.Invariant" = true' \
      EnemizerCLI.Core.runtimeconfig.json > runtimeconfig.json.new
    mv runtimeconfig.json.new EnemizerCLI.Core.runtimeconfig.json
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin
    cp -r . $out/lib/enemizer-cli
    chmod +x $out/lib/enemizer-cli/EnemizerCLI.Core $out/lib/enemizer-cli/createdump
    ln -s $out/lib/enemizer-cli/EnemizerCLI.Core $out/bin/enemizer-cli

    runHook postInstall
  '';

  meta = {
    description = "Enemy randomizer for The Legend of Zelda: A Link to the Past";
    homepage = "https://github.com/Ijwu/Enemizer";
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    license = lib.licenses.wtfpl;
    mainProgram = "enemizer-cli";
    platforms = ["x86_64-linux"];
  };
})
