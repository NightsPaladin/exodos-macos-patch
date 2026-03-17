#!/usr/bin/env python3
"""
create_kidsafe_xml.py — Generate xml/kidsafe/MS-DOS.xml from xml/family/MS-DOS.xml.

Removes games that are inappropriate for children under 18:
  • Rating == "M - Mature" (Doom, Quake, Blood, Carmageddon, etc.)
  • Games with adult/sexual themes in the title regardless of their rating
    (Leisure Suit Larry series, Duke Nukem's Penthouse Paradise, etc.)

Usage:
  python3 create_kidsafe_xml.py [--exodos-root PATH] [--remove-zips]

Options:
  --exodos-root PATH   Path to eXoDOS root (default: current working directory)
  --remove-zips        Also delete the game ZIP files for excluded games from
                       eXo/eXoDOS/<gamedir>/<Title (Year)>.zip
  --dry-run            List excluded games without writing any files
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import xml.etree.ElementTree as ET

# ── title-pattern blocklist ───────────────────────────────────────────────────
# These patterns are matched against the lowercase game title.
# They target adult/sexual content that is NOT already caught by the M rating.
_ADULT_TITLE_PATTERNS: list[str] = [
    r"leisure suit larry",
    r"larry vales",
    r"penthouse",       # Duke Nukem's Penthouse Paradise, Penthouse Hot Numbers, etc.
    r"playboy",
    r"hustler",
    r"strip poker",
    r"erotic",
    r"\bnude\b",
    r"sex games",
    r"adult party",
    r"\bporn\b",
    r"virtually nude",
    r"pink panther.*pinkadelic",   # pinkadelic pursuit is fine; target anything explicit
    r"duke nukem.*penthouse",
    r"samantha fox",               # strip poker
]
_COMPILED = [re.compile(p) for p in _ADULT_TITLE_PATTERNS]

_KIDSAFE_RATING_BLOCKLIST = {"M - Mature", "AO - Adults Only", "A - Adult"}

# ── helpers ───────────────────────────────────────────────────────────────────

def _text(elem: ET.Element, tag: str) -> str:
    child = elem.find(tag)
    return (child.text or "").strip() if child is not None and child.text else ""


def _is_excluded(title: str, rating: str) -> bool:
    if rating in _KIDSAFE_RATING_BLOCKLIST:
        return True
    tl = title.lower()
    return any(p.search(tl) for p in _COMPILED)


def _find_zip(dos_base: str, title: str, app_path: str) -> str | None:
    """Try to locate the installed ZIP for a game."""
    # app_path is typically like  eXo/eXoDOS/!dos/dune2/<Title>.bsh
    # The ZIPs are in eXo/eXoDOS/<Title (Year)>.zip or nearby
    parts = app_path.replace("\\", "/").split("/")
    if len(parts) >= 3:
        gamedir = parts[-2]   # e.g. "dune2"
        zip_base = os.path.join(dos_base, "..")  # eXo/eXoDOS/
        # Scan for a zip matching this gamedir inside eXo/eXoDOS/
        zip_dir = os.path.normpath(zip_base)
        for fname in os.listdir(zip_dir):
            if fname.lower().endswith(".zip") and gamedir in fname.lower():
                return os.path.join(zip_dir, fname)
    return None

# ── main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--exodos-root", default=os.getcwd(),
                        help="Path to eXoDOS root (default: cwd)")
    parser.add_argument("--remove-zips", action="store_true",
                        help="Delete game ZIPs for excluded games")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print excluded games only; do not write files")
    args = parser.parse_args()

    root = args.exodos_root
    family_xml = os.path.join(root, "xml", "family", "MS-DOS.xml")
    kidsafe_dir = os.path.join(root, "xml", "kidsafe")
    kidsafe_xml = os.path.join(kidsafe_dir, "MS-DOS.xml")
    dos_base = os.path.join(root, "eXo", "eXoDOS", "!dos")

    if not os.path.exists(family_xml):
        print(f"ERROR: Family XML not found at {family_xml}", file=sys.stderr)
        sys.exit(1)

    print(f"Reading: {family_xml}")
    ET.register_namespace("", "")
    tree = ET.parse(family_xml)
    xml_root = tree.getroot()

    excluded: list[tuple[str, str, str]] = []   # (title, rating, reason)
    to_remove: list[ET.Element] = []

    for elem in xml_root.findall("Game"):
        title  = _text(elem, "Title")
        rating = _text(elem, "Rating")
        if not title:
            continue
        if _is_excluded(title, rating):
            reason = f"rating={rating!r}" if rating in _KIDSAFE_RATING_BLOCKLIST else "title pattern"
            excluded.append((title, rating, reason))
            to_remove.append(elem)

    print(f"\nExcluding {len(to_remove):,} games from kid-safe XML:\n")
    for title, rating, reason in sorted(excluded, key=lambda x: x[0].lower()):
        print(f"  [{reason}]  {title}")

    print(f"\nKept:     {len(xml_root.findall('Game')) - len(to_remove):,} games")
    print(f"Excluded: {len(to_remove):,} games")

    if args.dry_run:
        print("\n[dry-run] No files written.")
        return

    # Remove excluded elements
    for elem in to_remove:
        xml_root.remove(elem)

    os.makedirs(kidsafe_dir, exist_ok=True)
    ET.indent(tree, space="  ")
    tree.write(kidsafe_xml, encoding="utf-8", xml_declaration=True)
    print(f"\nWrote: {kidsafe_xml}")

    if args.remove_zips:
        print("\nRemoving ZIPs for excluded games…")
        removed_count = 0
        for elem in to_remove:
            title    = _text(elem, "Title")
            app_path = _text(elem, "ApplicationPath")
            zip_path = _find_zip(dos_base, title, app_path)
            if zip_path and os.path.exists(zip_path):
                print(f"  rm {zip_path}")
                os.remove(zip_path)
                removed_count += 1
            else:
                print(f"  (no ZIP found for {title!r})")
        print(f"Removed {removed_count} ZIP files.")

    print("\nDone.  To activate: restart the GUI and choose \"Kid-Safe\" in Settings.")


if __name__ == "__main__":
    main()
