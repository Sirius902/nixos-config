{
  _7zz,
  fetchFromGitHub,
  lib,
  nix-update-script,
  sequence-otrizer,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "darunias-joy";
  version = "0-unstable-2026-08-25";

  src = fetchFromGitHub {
    owner = "DaruniasJoy";
    repo = "OoT-Custom-Sequences";
    rev = "5f0dc1780a3a2600f8b35531eaf88f6261883061";
    hash = "sha256-jRrB4Ry3E9ODP36vy066UobYH+/wqJVXktB+WwmknFk=";
  };

  nativeBuildInputs = [
    _7zz
    sequence-otrizer
  ];

  # Seven entries under data/Music are packed wrong as shipped: SequenceOTRizer
  # only takes a .seq with a same-stem .meta, and it names every entry
  # custom/music/<meta line 1>_<lowercased meta line 3>, so a stem mismatch or
  # a duplicated title drops a sequence without a word and a trailing space
  # rides into the name. The fixups below assert the value they replace, so
  # each one fails the build rather than rotting once upstream fixes its data.
  buildPhase = ''
    runHook preBuild

    find data/Music -name '*.ootrs' -print0 | while IFS= read -r -d "" archive; do
      7zz x -tzip -y -bso0 -bsp0 -o"''${archive%.ootrs}" "$archive"
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

    # TODO(Sirius902) Drop once the .seq entry in Blue Water Blue Sky -May's
    # Theme-.ootrs spells the apostrophe the way its .meta does: the zip holds
    # a CP932 quote in the one and an ASCII quote in the other, so the stems
    # never match.
    seqDir="data/Music/Guilty Gear Series/Guilty Gear X/Blue Water Blue Sky -May's Theme-"
    mv "$seqDir"/*.seq "$seqDir/Guilty Gear - Blue Water Blue Sky -May's Theme-.seq"

    # TODO(Sirius902) Drop once Oppressed People carries its own title rather
    # than a copy of the one next door, which it collides with and loses to.
    retitle "data/Music/Final Fantasy Series/Final Fantasy VII/Oppressed People/Final Fantasy VII - Oppressed People.meta" \
      1 'Final Fantasy vii - Forested Temple' 'Final Fantasy VII - Oppressed People'

    # TODO(Sirius902) Drop once the Hyperdimension Neptunia copies of these two
    # are titled as the alternate arrangements they are, the way Mega Man X -
    # Armored Armadillo v2 already is. Each pair is distinct .seq data on a
    # distinct soundfont, so both are worth shipping, but sharing a title costs
    # the standalone Mega Man Series copy.
    retitle "data/Music/Hyperdimension Neptunia/Mega Man Series/Mega Man 2/Bubble Man/Mega Man 2 - Bubble Man.meta" \
      1 'Mega Man 2 - Bubble Man' 'Mega Man 2 - Bubble Man v2'
    retitle "data/Music/Hyperdimension Neptunia/Mega Man Series/Mega Man 2/Crash Man/Mega Man 2 - Crash Man.meta" \
      1 'Mega Man 2 - Crash Man' 'Mega Man 2 - Crash Man v2'

    # TODO(Sirius902) Drop once these two titles lose the trailing space that
    # StringUtils::Sanitize leaves alone and the archive name keeps.
    retitle "data/Music/The Legend of Zelda Series/A Link to the Past/Death Mountain/Death Mountain.meta" \
      1 'The Legend of Zelda: A Link to the Past - Death Mountain ' \
      'The Legend of Zelda: A Link to the Past - Death Mountain'
    retitle "data/Music/The Legend of Zelda Series/A Link to the Past/Fanfare - Ocarina/Fanfare - Ocarina.meta" \
      1 'The Legend of Zelda: A Link to the Past - Ocarina ' \
      'The Legend of Zelda: A Link to the Past - Ocarina'

    # TODO(Sirius902) Drop once Boss Defeated's type loses its trailing space,
    # which mangles the archive name and knocks CachePolicy down to 1.
    retitle "data/Music/The Legend of Zelda Series/Twilight Princess/Boss Defeated/Boss Defeated.meta" \
      3 'bgm ' bgm

    SequenceOTRizer --seq-path data/Music --otr-name daruniasjoy

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 -t $out/share/darunias-joy mods/daruniasjoy.otr
    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version=branch=Custom-Music-2.0"
        "--version-regex=(0-unstable-.*)"
      ];
    };

    tests.otr = sequence-otrizer.mkOtrTest {
      pack = finalAttrs.finalPackage;
      inherit (finalAttrs) src;
      otr = "share/darunias-joy/daruniasjoy.otr";
    };
  };

  __structuredAttrs = true;
  strictDeps = true;
  dontConfigure = true;

  meta = {
    homepage = "https://github.com/DaruniasJoy/OoT-Custom-Sequences";
    description = "Darunia's Joy";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [sirius902];
  };
})
