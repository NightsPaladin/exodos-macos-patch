#!/usr/bin/env python3
"""
build_patch.py — Build the eXoDOS macOS patch ZIP.

Run from the eXoDOS root:
    python3 build_patch.py

Produces: eXoDOS_macOS_Patch_v6.04.zip

This patch supplements the official eXoDOS Linux patch (which must be applied
first) and adds macOS support on top of it. It must be extracted on top of the
Linux patch. After extracting:
  1. Run: python3 unify_scripts.py
     This transforms per-game .bsh/.command files to thin wrappers sourcing
     exo_lib.sh, strips exception.bsh boilerplate, and converts all remaining
     .bsh/.msh pairs in util/, xml/, dosbox/, Update/, and Sumatra/ to unified
     .sh files with OS-detection. Once verified, run:
     python3 unify_scripts.py --purge-backups

What this patch provides (the Linux patch already provides everything else):
  - macOS-specific documentation and README
  - macOS dependency installer
  - exo_lib.sh — shared shell library with macOS OS-detection logic
  - Unified .sh scripts — OS-detecting replacements for Linux .bsh/.msh pairs
  - dosbox_macos.txt and options_macos.conf — macOS DOSBox emulator config
  - unify_scripts.py — one-time script to upgrade the Linux patch scripts
  - create_kidsafe_xml.py — shared utility

NOT included (already provided by the Linux patch):
  - Per-game dosbox_linux.conf files (~7,666 files)
  - Linux .bsh/.msh script originals
  - Linux dosbox .conf variants (Staging, ase, gbc, etc.)
  - Flatpaks, AppImages, and other Linux-only binaries
  - Update/, xml/, Sumatra/, eXoMerge, Setup scripts

NOT included (distributed separately as eXoGUI_vX.Y.Z.zip):
  - exogui-pyqt — cross-platform PyQt6 GUI (run from the volume root, above eXoDOS)
  - exogui.command — GUI launcher
"""

import argparse
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).parent

OUTPUT_ZIP = ROOT / "eXoDOS_macOS_Patch_v6.04.zip"


def _parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--output", metavar="PATH",
        help=f"Override output ZIP path (default: {OUTPUT_ZIP.name})",
    )
    return parser.parse_args()

# Files/dirs to include, as (source_path, zip_path) pairs.
# source_path is relative to ROOT; zip_path is the path inside the ZIP.
INCLUDES = [
    # ── Documentation ─────────────────────────────────────────────────────────
    ("eXoDOS macOS ReadMe.txt",                 "eXoDOS macOS ReadMe.txt"),
    ("macOS README.md",                         "macOS README.md"),
    ("macOS_compatibility_notes.md",            "macOS_compatibility_notes.md"),

    # ── Root-level launchers ──────────────────────────────────────────────────
    ("install_dependencies.command",            "install_dependencies.command"),

    # ── Unification script (runs once after patch is extracted) ───────────────
    ("unify_scripts.py",                        "unify_scripts.py"),

    # ── Shared library (with macOS OS-detection) ──────────────────────────────
    ("eXo/util/exo_lib.sh",                     "eXo/util/exo_lib.sh"),

    # ── Launch chain (updated with macOS support) ─────────────────────────────
    ("eXo/util/launch.msh",                     "eXo/util/launch.msh"),
    ("eXo/util/launch_helper.sh",               "eXo/util/launch_helper.sh"),

    # ── Unified .sh scripts (OS-detecting; replace Linux .bsh/.msh pairs) ─────
    ("eXo/util/AltLauncher.sh",                 "eXo/util/AltLauncher.sh"),
    ("eXo/util/install.sh",                     "eXo/util/install.sh"),
    ("eXo/util/ip.sh",                          "eXo/util/ip.sh"),
    ("eXo/util/version.sh",                     "eXo/util/version.sh"),
    ("eXo/util/version.command",                "eXo/util/version.command"),
    ("eXo/util/Sumatra/CallSumatra.sh",         "eXo/util/Sumatra/CallSumatra.sh"),
    ("eXo/util/Sumatra/CallSumatra.command",    "eXo/util/Sumatra/CallSumatra.command"),

    # ── Unified .sh scripts for language packs ────────────────────────────────
    ("eXo/util/!languagepacks/Alternate Launcher.sh",   "eXo/util/!languagepacks/Alternate Launcher.sh"),
    ("eXo/util/!languagepacks/install.sh",              "eXo/util/!languagepacks/install.sh"),
    ("eXo/util/!languagepacks/ip.sh",                   "eXo/util/!languagepacks/ip.sh"),
    ("eXo/util/!languagepacks/launch.sh",               "eXo/util/!languagepacks/launch.sh"),

    # ── DOSBox emulator lookup table (macOS) ──────────────────────────────────
    ("eXo/util/dosbox_macos.txt",               "eXo/util/dosbox_macos.txt"),

    # ── DOSBox configs (macOS) ────────────────────────────────────────────────
    ("eXo/emulators/dosbox/options_macos.conf", "eXo/emulators/dosbox/options_macos.conf"),

    # ── DOSBox scripts (unified .sh — replace Linux .bsh-only originals) ──────
    ("eXo/emulators/dosbox/config.sh",                      "eXo/emulators/dosbox/config.sh"),
    ("eXo/emulators/dosbox/config.command",                 "eXo/emulators/dosbox/config.command"),
    ("eXo/emulators/dosbox/DOSBox 0.74 Options.sh",         "eXo/emulators/dosbox/DOSBox 0.74 Options.sh"),
    ("eXo/emulators/dosbox/DOSBox 0.74 Options.command",    "eXo/emulators/dosbox/DOSBox 0.74 Options.command"),
    ("eXo/emulators/dosbox/Reset KeyMapper.sh",             "eXo/emulators/dosbox/Reset KeyMapper.sh"),
    ("eXo/emulators/dosbox/Reset KeyMapper.command",        "eXo/emulators/dosbox/Reset KeyMapper.command"),
    ("eXo/emulators/dosbox/Reset Options.sh",               "eXo/emulators/dosbox/Reset Options.sh"),
    ("eXo/emulators/dosbox/Reset Options.command",          "eXo/emulators/dosbox/Reset Options.command"),
    ("eXo/emulators/dosbox/GunStick_dosbox/Reset Options.sh",      "eXo/emulators/dosbox/GunStick_dosbox/Reset Options.sh"),
    ("eXo/emulators/dosbox/GunStick_dosbox/Reset Options.command",  "eXo/emulators/dosbox/GunStick_dosbox/Reset Options.command"),
    ("eXo/emulators/dosbox/!languagepacks/config.sh",       "eXo/emulators/dosbox/!languagepacks/config.sh"),
    ("eXo/emulators/dosbox/!languagepacks/config.command",  "eXo/emulators/dosbox/!languagepacks/config.command"),

    # ── Shared tools ──────────────────────────────────────────────────────────
    ("create_kidsafe_xml.py",                   "create_kidsafe_xml.py"),

    # ── Per-game macOS overrides ───────────────────────────────────────────────
    # Games that used Wine+mouse helper on Linux; fixed via DOSBox Staging mouse tuning.
    ("eXo/eXoDOS/!dos/dune2/dosbox_macos.conf",     "eXo/eXoDOS/!dos/dune2/dosbox_macos.conf"),
    ("eXo/eXoDOS/!dos/dune2/exception.sh",           "eXo/eXoDOS/!dos/dune2/exception.sh"),
    ("eXo/eXoDOS/!dos/SkyNET/dosbox_macos.conf",     "eXo/eXoDOS/!dos/SkyNET/dosbox_macos.conf"),
    ("eXo/eXoDOS/!dos/SkyNET/exception.sh",          "eXo/eXoDOS/!dos/SkyNET/exception.sh"),
    ("eXo/eXoDOS/!dos/TermFS/dosbox_macos.conf",     "eXo/eXoDOS/!dos/TermFS/dosbox_macos.conf"),
    ("eXo/eXoDOS/!dos/TermFS/exception.sh",          "eXo/eXoDOS/!dos/TermFS/exception.sh"),
    ("eXo/eXoDOS/!dos/WarCraft/dosbox_macos.conf",   "eXo/eXoDOS/!dos/WarCraft/dosbox_macos.conf"),
    ("eXo/eXoDOS/!dos/WarCraft/exception.sh",        "eXo/eXoDOS/!dos/WarCraft/exception.sh"),
]

# Extensions and directories to skip when recursing into directories
SKIP_EXTS = {".pyc", ".pyo"}
SKIP_DIRS = {"__pycache__", ".git", ".mypy_cache"}
# Suffixes that indicate backup files left by unify_scripts.py — never ship these
SKIP_SUFFIXES_ENDING = (".bsh.bak", ".command.bak", ".msh.bak")


def add_path(zf: zipfile.ZipFile, src: Path, arc: str) -> int:
    """Add a file or directory tree to the ZIP. Returns count of files added."""
    count = 0
    if src.is_file():
        zf.write(src, arc)
        count += 1
    elif src.is_dir():
        for child in sorted(src.rglob("*")):
            if child.name.startswith(".") or child.name.startswith("._"):
                continue
            if any(part in SKIP_DIRS for part in child.parts):
                continue
            if child.suffix in SKIP_EXTS:
                continue
            if any(child.name.endswith(s) for s in SKIP_SUFFIXES_ENDING):
                continue
            if child.is_file():
                rel = child.relative_to(src)
                zf.write(child, f"{arc}/{rel}")
                count += 1
    else:
        print(f"  WARNING: {src} not found, skipping", file=sys.stderr)
    return count


def main() -> None:
    args = _parse_args()
    output_zip = Path(args.output) if args.output else OUTPUT_ZIP

    print(f"Building macOS patch ZIP: {output_zip.name}")
    print(f"Source root: {ROOT}")
    print()

    total = 0
    with zipfile.ZipFile(output_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for src_rel, arc_path in INCLUDES:
            src = ROOT / src_rel
            n = add_path(zf, src, arc_path)
            print(f"  {'DIR' if src.is_dir() else 'FILE':<5} {arc_path}  ({n} file{'s' if n != 1 else ''})")
            total += n

    size_mb = output_zip.stat().st_size / 1024 / 1024
    print()
    print(f"Done. {total} files → {output_zip.name} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()

