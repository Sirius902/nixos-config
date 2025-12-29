#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages(ps: with ps; [ httpx ])" nix
"""
Fetches and updates taglists based on https://github.com/Mic92/nix-update and nixpkgs update script.
"""
import asyncio
import hashlib
from typing import Any, Final
import httpx
import json
from pathlib import Path
from subprocess import check_output
import sys
from urllib.parse import urlparse
import xml.etree.ElementTree as ET

ROOT: Final[str] = (
    check_output(
        [
            "git",
            "rev-parse",
            "--show-toplevel",
        ]
    )
    .decode("utf-8")
    .strip()
)

GAMES: Final[dict[str, str]] = {
    "Enderal": "enderal",
    "Fallout3": "fallout3",
    "FalloutNV": "falloutnv",
    "Fallout4": "fallout4",
    "Morrowind": "morrowind",
    "Oblivion": "oblivion",
    "Skyrim": "skyrim",
    "SkyrimSE": "skyrimse",
    "Starfield": "starfield",
}


def eprint(*args: Any, **kwargs: Any) -> None:
    print(*args, file=sys.stderr, **kwargs)


async def check_subprocess_output(*args: str, **kwargs: Any) -> bytes:
    """
    Emulate check and capture_output arguments of subprocess.run function.
    """
    process = await asyncio.create_subprocess_exec(*args, **kwargs)
    # We need to use communicate() instead of wait(), as the OS pipe buffers
    # can fill up and cause a deadlock.
    stdout, stderr = await process.communicate()

    if process.returncode != 0:
        error = stderr.decode()
        raise RuntimeError(f"{args} failed: {error}")

    return stdout


async def hash_to_sri(hex: str) -> str:
    out = await check_subprocess_output(
        "nix",
        "hash",
        "convert",
        "--hash-algo",
        "sha256",
        "--to",
        "sri",
        hex,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    hash = out.decode("utf-8").strip()
    return hash


async def fetch_game_data(client: httpx.AsyncClient, game: str, repo: str):
    atom_response = await client.get(
        f"https://github.com/loot/{repo}/commits/v0.26.atom"
    )
    atom_response.raise_for_status()

    tree = ET.fromstring(atom_response.text)
    commits = tree.findall(".//{http://www.w3.org/2005/Atom}entry")
    if len(commits) == 0:
        msg = "Cannot parse ATOM feed: missing commit"
        raise RuntimeError(msg)

    commit = commits[0]
    link = commit.find("{http://www.w3.org/2005/Atom}link")
    if link is None:
        msg = "Cannot parse ATOM feed: missing link"
        raise RuntimeError(msg)

    updated = commit.find("{http://www.w3.org/2005/Atom}updated")
    if updated is None:
        msg = "Cannot parse ATOM feed: missing updated element"
        raise RuntimeError(msg)
    if updated.text is None:
        msg = "Cannot parse ATOM feed: updated element has no text"
        raise RuntimeError(msg)

    url = urlparse(link.attrib["href"])
    commit = url.path.rsplit("/", maxsplit=1)[-1]

    taglist_url = (
        f"https://raw.githubusercontent.com/loot/{repo}/{commit}/masterlist.yaml"
    )
    taglist_response = await client.get(taglist_url)
    taglist_response.raise_for_status()

    hash = hashlib.sha256(taglist_response.content).hexdigest()
    return game, {
        "url": taglist_url,
        "hash": await hash_to_sri(hash),
    }


async def main() -> None:
    try:
        async with httpx.AsyncClient() as client:
            tasks = [
                fetch_game_data(client, game, repo) for game, repo in GAMES.items()
            ]
            results = await asyncio.gather(*tasks)
    except KeyboardInterrupt:
        eprint("Cancelling...")
        raise asyncio.exceptions.CancelledError()

    taglists = dict(sorted(results))

    with open(
        Path(ROOT).joinpath("pkgs/wrye-bash/taglists.json"), "w", encoding="utf-8"
    ) as f:
        json.dump(taglists, f, indent=2, ensure_ascii=False)
        f.write("\n")

    changed_files_output = await check_subprocess_output(
        "git",
        "diff",
        "--name-only",
        "HEAD",
        "--",
        "pkgs/wrye-bash/taglists.json",
        stdout=asyncio.subprocess.PIPE,
        cwd=ROOT,
    )
    changed_files = changed_files_output.decode("utf-8").splitlines()
    if len(changed_files) == 0:
        return

    await check_subprocess_output("git", "add", *changed_files, cwd=ROOT)
    await check_subprocess_output(
        "git", "commit", "--quiet", "-m", "wrye-bash: update taglists.json", cwd=ROOT
    )


if __name__ == "__main__":
    asyncio.run(main())
