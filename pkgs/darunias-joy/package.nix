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
  pname = "darunias-joy";
  version = "0-unstable-2026-10-21";

  src = fetchFromGitHub {
    owner = "DaruniasJoy";
    repo = "OoT-Custom-Sequences";
    rev = "8254b4470a88c48fd3da9b75d257f16f7b777da3";
    hash = "sha256-Vg9DHysRQEpK6OwY7d13p4angqQs27iXNCAQTfqZ/8o=";
  };

  nativeBuildInputs = [sequence-otrizer];

  # Some entries under data/Music are packed wrong as shipped: SequenceOTRizer
  # only takes a .seq with a same-stem .meta, and it names every entry
  # custom/music/<meta line 1>_<lowercased meta line 3>, so a stem mismatch or
  # a duplicated title drops a sequence without a word and a trailing space
  # rides into the name. The fixups below assert the value they replace, so
  # each one fails the build rather than rotting once upstream fixes its data.
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

    # TODO(Sirius902) Drop once Oppressed People carries its own title rather
    # than a copy of the one next door, which it collides with and loses to.
    retitle "data/Music/Final Fantasy VII/Oppressed People/Final Fantasy VII - Oppressed People.meta" \
      1 'Final Fantasy vii - Forested Temple' 'Final Fantasy VII - Oppressed People'

    # TODO(Sirius902) Drop once the numbered copies of these are titled as the
    # alternate arrangements they are, the way Mega Man X - Armored Armadillo
    # v2 already is. Each copy is distinct .seq data, so all are worth
    # shipping, but sharing a title costs all but one of them its entry.
    retitle "data/Music/Brave Fencer Musashi/Twinpeak Mountain [2]/Brave Fencer Musashi - Twinpeak Mountain.meta" \
      1 'Brave Fencer Musashi - Twinpeak Mountain' 'Brave Fencer Musashi - Twinpeak Mountain v2'
    retitle "data/Music/Mega Man 2/Air Man [3]/MM2 AM.meta" \
      1 'Mega Man 2 - Air Man' 'Mega Man 2 - Air Man v3'
    retitle "data/Music/Mega Man 2/Bubble Man [2]/Mega Man 2 - Bubble Man.meta" \
      1 'Mega Man 2 - Bubble Man' 'Mega Man 2 - Bubble Man v2'
    retitle "data/Music/Mega Man 2/Bubble Man [3]/MM2 BM.meta" \
      1 'Mega Man 2 - Bubble Man' 'Mega Man 2 - Bubble Man v3'
    retitle "data/Music/Mega Man 2/Crash Man [2]/Mega Man 2 - Crash Man.meta" \
      1 'Mega Man 2 - Crash Man' 'Mega Man 2 - Crash Man v2'
    retitle "data/Music/Mega Man 2/Crash Man [3]/MM2 CM.meta" \
      1 'Mega Man 2 - Crash Man' 'Mega Man 2 - Crash Man v3'
    retitle "data/Music/Mega Man 3/Hard Man [2]/Mega Man 3 - Hard Man.meta" \
      1 'Mega Man 3 - Hard Man' 'Mega Man 3 - Hard Man v2'
    retitle "data/Music/Mega Man 3/Snake Man [2]/Mega Man 3 - Snake Man.meta" \
      1 'Mega Man 3 - Snake Man' 'Mega Man 3 - Snake Man v2'
    retitle "data/Music/Mega Man 3/Spark Man [2]/Mega Man 3 - Spark Man.meta" \
      1 'Mega Man 3 - Spark Man' 'Mega Man 3 - Spark Man v2'
    retitle "data/Music/Mega Man X2/Bubble Crab [2]/MMX2 BC2.meta" \
      1 'Mega Man X2 - Bubble Crab' 'Mega Man X2 - Bubble Crab v2'

    # TODO(Sirius902) Drop once these titles lose the trailing space that
    # StringUtils::Sanitize leaves alone and the archive name keeps.
    retitle "data/Music/Mega Man X Corrupted/Crystal Rafflar/MMX Corrupted - Crystal Raffler.meta" \
      1 'MMX Corrupted - Crystal Raffler ' 'MMX Corrupted - Crystal Raffler'
    retitle "data/Music/The Legend of Zelda A Link to the Past/Death Mountain/Death Mountain.meta" \
      1 'The Legend of Zelda: A Link to the Past - Death Mountain ' \
      'The Legend of Zelda: A Link to the Past - Death Mountain'
    retitle "data/Music/The Legend of Zelda A Link to the Past/Ocarina/Fanfare - Ocarina.meta" \
      1 'The Legend of Zelda: A Link to the Past - Ocarina ' \
      'The Legend of Zelda: A Link to the Past - Ocarina'

    # TODO(Sirius902) Drop once Boss Defeated's type loses its trailing space,
    # which mangles the archive name and knocks CachePolicy down to 1.
    retitle "data/Music/The Legend of Zelda Twilight Princess/Boss Defeated/Boss Defeated.meta" \
      3 'bgm ' bgm

    SequenceOTRizer --seq-path data/Music --otr-name daruniasjoy

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 -t $out/share/darunias-joy mods/daruniasjoy.otr
    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [(python3.withPackages (ps: [ps.mpyq]))];

  installCheckPhase = ''
    runHook preInstallCheck

    python3 ${sequence-otrizer.checkOtr} data/Music "$out/share/darunias-joy/daruniasjoy.otr"

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version=branch=Custom-Music-2.0"
        "--version-regex=(0-unstable-.*)"
      ];
    };
  };

  __structuredAttrs = true;
  strictDeps = true;
  dontConfigure = true;

  meta = {
    homepage = "https://github.com/DaruniasJoy/OoT-Custom-Sequences";
    description = "Custom Ocarina of Time music sequences for Ship of Harkinian";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [sirius902];
  };
}
