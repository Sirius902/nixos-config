"""
Check that a sequence pack's OTR holds one well-formed entry per packable
sequence in its source tree.

SequenceOTRizer skips a folder whose .ootrs carries a .zbank, and reports it.
Everything else it drops -- a .seq with no same-stem .meta, a title that
collides with one already added -- it drops silently, and it logs the AddFile
that failed as if it had worked. So the source tree is the only honest count of
what should be in the archive.
"""

import re
import sys
import zipfile
from pathlib import Path

import mpyq  # type: ignore[import-untyped]

# custom/music/<meta line 1>_<lowercased meta line 3>, per
# ZeldaOTRizer::Sequence::FromSeqFile.
NAME_RE = re.compile(r"^custom/music/(?P<title>.+)_(?:bgm|fanfare)$")


def candidates(music: Path) -> list[Path]:
    """The .ootrs under `music` that SequenceOTRizer should pack."""
    found = []
    for ootrs in sorted(music.rglob("*.ootrs")):
        with zipfile.ZipFile(ootrs) as zf:
            suffixes = {Path(n).suffix.lower() for n in zf.namelist()}
        if ".zbank" in suffixes:
            continue
        # A stem mismatch between the two is a defect, but the source tree is
        # read unfixed, so it can only be caught by the entry count below.
        if not {".seq", ".meta"} <= suffixes:
            sys.exit(f"error: {ootrs} has no .seq/.meta pair")
        found.append(ootrs)
    return found


def main(music: Path, otr: Path) -> None:
    expected = candidates(music)
    listfile = mpyq.MPQArchive(str(otr)).read_file("(listfile)").decode("utf-8")
    names = [line for line in listfile.replace("\r\n", "\n").split("\n") if line]

    if len(names) != len(expected):
        sys.exit(
            f"error: {otr} holds {len(names)} entries for {len(expected)} "
            f"sequences in {music}; something was dropped or collided"
        )

    # MPQ hashes names case-insensitively, so a case-only clash would have cost
    # an entry above; this says so directly if the counts ever line up anyway.
    if len({n.lower() for n in names}) != len(names):
        sys.exit(f"error: {otr} holds names differing only in case")

    for name in names:
        match = NAME_RE.match(name)
        if match is None:
            sys.exit(f"error: {otr} holds malformed entry name {name!r}")
        title = match["title"]
        if not title or title != title.strip():
            sys.exit(f"error: {otr} entry {name!r} has an untrimmed title")

    print(f"{otr}: {len(names)} sequences, all named, all distinct")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(f"usage: {sys.argv[0]} <music-dir> <otr-file>")
    main(Path(sys.argv[1]), Path(sys.argv[2]))
