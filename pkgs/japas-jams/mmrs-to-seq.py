"""
Lay out a SequenceOTRizer input tree from upstream's .mmrs archives.

A .ootrs pack ships the .seq and .meta pair SequenceOTRizer reads. A .mmrs
ships neither: the sequence carries the instrument set in its file name, and
the title and bgm/fanfare type live in z64packer's song and game manifests. So
the pair has to be written here.

SequenceOTRizer drops a folder it cannot use -- no .seq/.meta pair, a title
already taken -- without a word, and logs the AddFile that failed as if it had
worked. Every mismatch below is therefore fatal rather than skipped.
"""

import json
import re
import sys
import zipfile
from collections import Counter
from pathlib import Path
from typing import Any

# Upstream's z64packer/sequtils.py counts any of these as the sequence.
SEQ_SUFFIXES = frozenset({".aseq", ".seq", ".zseq"})

FONT_RE = re.compile(r"(?:0[xX])?[0-9a-fA-F]+")


def load_manifest(path: Path) -> list[dict[str, Any]]:
    """The object entries of a z64packer manifest."""
    entries = json.loads(path.read_text(encoding="utf-8-sig"))
    return [entry for entry in entries if isinstance(entry, dict)]


def sequence_member(archive: Path) -> str | None:
    """The sequence in `archive`, or None if it is one SequenceOTRizer skips."""
    with zipfile.ZipFile(archive) as zf:
        names = zf.namelist()
    # A sequence resource carries a bank index, not a bank, so SequenceOTRizer
    # refuses a folder shipping its own .zbank.
    if any(Path(name).suffix.lower() == ".zbank" for name in names):
        return None
    seqs = [name for name in names if Path(name).suffix.lower() in SEQ_SUFFIXES]
    if len(seqs) != 1:
        sys.exit(f"error: {archive} holds {len(seqs)} sequences, not one")
    return seqs[0]


def font_index(archive: Path, member: str) -> int:
    """The instrument set `member` is named for, as the resource holds it."""
    stem = Path(member).stem
    if FONT_RE.fullmatch(stem) is None:
        sys.exit(f"error: {archive} names its sequence {stem!r}, not an instrument set")
    font = int(stem, 16)
    if font > 0xFF:
        sys.exit(f"error: {archive} asks for instrument set {font:#x}, past 0xFF")
    return font


def main(src: Path, out: Path) -> None:
    music = src / "Music"
    songs = load_manifest(src / "z64packer" / "z64songs.json")
    short_names = {
        game["game"]: game["short_name"]
        for game in load_manifest(src / "z64packer" / "z64games.json")
        if game.get("short_name")
    }

    described = Counter(song["file"] for song in songs)
    present = Counter(str(p.relative_to(music)) for p in music.rglob("*.mmrs"))
    if described != present:
        disagree = (described - present) + (present - described)
        sys.exit(
            f"error: z64songs.json and {music} disagree on {sorted(disagree)[:5]}"
        )

    titles: dict[str, Path] = {}
    packed = 0
    for song in songs:
        archive = music / song["file"]
        member = sequence_member(archive)
        if member is None:
            continue
        font = font_index(archive, member)

        kind = song["type"]
        if kind not in ("bgm", "fanfare"):
            sys.exit(f"error: {archive} is a {kind!r}, not a bgm or fanfare")

        # z64packer titles a song by its game's short name wherever it has one,
        # so an f"{game} - {song}" here would diverge from every title upstream
        # ships in its own packs.
        title = f"{short_names.get(song['game'], song['game'])} - {song['song']}"
        if not title or title != title.strip():
            sys.exit(f"error: {archive} would be titled {title!r}")
        clash = titles.setdefault(title.lower(), archive)
        if clash != archive:
            sys.exit(f"error: {archive} and {clash} would both be titled {title!r}")

        folder = out / song["file"].removesuffix(".mmrs")
        folder.mkdir(parents=True)
        with zipfile.ZipFile(archive) as zf:
            (folder / "sequence.seq").write_bytes(zf.read(member))
        (folder / "sequence.meta").write_text(
            f"{title}\n{font:X}\n{kind}\n", encoding="utf-8"
        )
        packed += 1

    print(f"{out}: {packed} sequences of {len(songs)}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(f"usage: {sys.argv[0]} <src-root> <out-dir>")
    main(Path(sys.argv[1]), Path(sys.argv[2]))
