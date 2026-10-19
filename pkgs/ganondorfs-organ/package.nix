{
  _7zz,
  fetchFromGitHub,
  lib,
  nix-update-script,
  python3,
  sequence-otrizer,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "ganondorfs-organ";
  version = "0-unstable-2026-10-19";

  src = fetchFromGitHub {
    owner = "GanondorfsOrgan";
    repo = "Ganondorfs-Organ";
    rev = "fc62d07f4ea02f0a94a1474f003e0976b2cdba31";
    hash = "sha256-yIFBZSuCeQK6jRIDmCEfbg4lv0BTdrHQreV047RiwN8=";
  };

  nativeBuildInputs = [sequence-otrizer];

  buildPhase = ''
    runHook preBuild

    # TODO(Sirius902) Move _7zz back to nativeBuildInputs once its setup hook
    # leaves directory sources to the default unpacker instead of extracting
    # every archive under them.
    find data/Music -name '*.ootrs' -print0 | while IFS= read -r -d "" archive; do
      ${lib.getExe _7zz} x -tzip -y -bso0 -bsp0 -o"''${archive%.ootrs}" "$archive"
    done

    retitle() { # <meta> <line> <expected> <replacement>
      local got
      got="$(sed -n "$2p" "$1" | tr -d '\r')"
      if [ "$got" != "$3" ]; then
        echo "error: $1 line $2 is '$got', not '$3'; drop this workaround" >&2
        exit 1
      fi
      sed -i "$2s/.*/$4/" "$1"
    }

    # TODO(Sirius902) Drop once Alice in Wonderland's .seq is cased the way its
    # .meta is, which SequenceOTRizer needs to pair the two.
    seqDir="data/Music/Touhou 5 Mystic Square/Alice in Wonderland"
    mv "$seqDir/Touhou 5 - Alice in wonderland.seq" "$seqDir/Touhou 5 - Alice in Wonderland.seq"

    # TODO(Sirius902) Drop once the Lunatic Eyes ~ Invisible Full Moon copy is
    # titled as the alternate arrangement it is. Its .seq data is distinct from
    # the Lunatic Eyes copy beside it, so both are worth shipping, but sharing
    # a title costs one of the two its entry.
    retitle "data/Music/Touhou 8 Imperishable Night/Lunatic Eyes ~ Invisible Full Moon/Touhou 8 - Lunatic Eyes ~ Invisible Full Moon.meta" \
      1 'Touhou 8 - Lunatic Eyes ~ Invisible Full Moon' \
      'Touhou 8 - Lunatic Eyes ~ Invisible Full Moon v2'

    SequenceOTRizer --seq-path data/Music --otr-name ganondorfsorgan

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 -t $out/share/ganondorfs-organ mods/ganondorfsorgan.otr
    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [(python3.withPackages (ps: [ps.mpyq]))];

  installCheckPhase = ''
    runHook preInstallCheck

    python3 ${sequence-otrizer.checkOtr} data/Music "$out/share/ganondorfs-organ/ganondorfsorgan.otr"

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version=branch=main"
        "--version-regex=(0-unstable-.*)"
      ];
    };
  };

  __structuredAttrs = true;
  strictDeps = true;
  dontConfigure = true;

  meta = {
    homepage = "https://github.com/GanondorfsOrgan/Ganondorfs-Organ";
    description = "Custom Ocarina of Time music sequences for Ship of Harkinian";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [sirius902];
  };
}
