"""
Check that a sequence pack's OTR holds one well-formed entry per packable
sequence in the tree it was packed from.

SequenceOTRizer takes folders, not archives: it walks the tree for directories,
skips one holding a .zbank, and packs the .seq that has a same-stem .meta beside
it. Everything else it drops -- a .seq with no .meta, a second pair in the same
folder, a title that collides with one already added -- it drops silently, and
it logs the AddFile that failed as if it had worked. So the tree is the only
honest count of what should be in the archive.
"""

import re
import sys
from pathlib import Path

import mpyq  # type: ignore[import-untyped]

# custom/music/<meta line 1>_<lowercased meta line 3>, per
# ZeldaOTRizer::Sequence::FromSeqFile.
NAME_RE = re.compile(r"^custom/music/(?P<title>.+)_(?:bgm|fanfare)$")


def packable(tree: Path) -> int:
    """How many folders under `tree` SequenceOTRizer packs a sequence from."""
    packed = 0
    for folder in sorted(p for p in tree.rglob("*") if p.is_dir()):
        entries = sorted(folder.iterdir())
        # A sequence resource carries a bank index rather than a bank, so a
        # folder shipping its own .zbank is skipped whole.
        if any(entry.suffix == ".zbank" for entry in entries):
            continue
        seqs = [entry for entry in entries if entry.suffix == ".seq"]
        paired = [seq for seq in seqs if seq.with_suffix(".meta").exists()]
        for seq in seqs:
            if seq not in paired:
                sys.exit(f"error: {seq} has no {seq.with_suffix('.meta').name}")
        if len(paired) > 1:
            sys.exit(f"error: {folder} holds {len(paired)} sequences, not one")
        packed += len(paired)
    if not packed:
        sys.exit(f"error: {tree} holds no sequence to pack")
    return packed


def main(tree: Path, otr: Path) -> None:
    expected = packable(tree)
    listfile = mpyq.MPQArchive(str(otr)).read_file("(listfile)").decode("utf-8")
    names = [line for line in listfile.replace("\r\n", "\n").split("\n") if line]

    if len(names) != expected:
        sys.exit(
            f"error: {otr} holds {len(names)} entries for {expected} "
            f"sequences in {tree}; something was dropped or collided"
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
        sys.exit(f"usage: {sys.argv[0]} <seq-tree> <otr-file>")
    main(Path(sys.argv[1]), Path(sys.argv[2]))
