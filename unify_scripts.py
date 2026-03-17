#!/usr/bin/env python3
"""unify_scripts.py — Comprehensive eXoDOS Linux+macOS script unification.

Modes (run in sequence by default, or individually via flags):
  A. game-bsh      — Replace per-game .bsh/.command with thin exo_launch/exo_install wrappers
  B. strip-exc     — Strip Linux boilerplate from exception.bsh (leaving only unique logic)
  1. xml           — Merge .bsh/.msh pairs in xml/ into unified .sh files
  2. util          — Merge .bsh/.msh pairs in eXo/util/ (and !languagepacks/) into unified .sh files
  3. exceptions    — Transform all exception.bsh to exception.sh with macOS support
  4. launch        — Update launch.bsh and launch.msh to look for exception.sh first
  5. bshonly       — Convert .bsh-only scripts (no .msh) in dosbox/, Update/, Sumatra/ to
                     unified .sh files; replace their .command files with thin macOS wrappers

Standalone utility (not part of default run, always requires explicit flag):
  --purge-backups  — Remove all backup files created by previous unify runs:
                       *.bsh.bak and *.command.bak throughout the game tree,
                       launch.bsh.bak / launch.msh.bak in eXo/util/,
                       and the _backup_<timestamp>/ directory at the root.
                     Always prompts for confirmation. Safe to run after verifying the
                     unified scripts work correctly.

Generated .sh files source exo_lib.sh which provides:
  goto, dynchoice, _SED (cross-platform sed), bash version guard, Homebrew PATH.

Usage:
    python3 unify_scripts.py [--dry-run] [--game-bsh] [--strip-exc] [--xml] [--util] [--exceptions] [--launch] [--bshonly]
    (with no mode flags, all seven modes run in sequence)
    python3 unify_scripts.py --purge-backups
"""

import os
import re
import sys
import argparse
import shutil
from pathlib import Path
from datetime import datetime

try:
    import termios as _termios
    _HAS_TERMIOS = True
except ImportError:
    _HAS_TERMIOS = False

# Configuration
EXODOS_ROOT  = Path(__file__).parent.resolve()
XML_DIR      = EXODOS_ROOT / "xml"
UTIL_DIR     = EXODOS_ROOT / "eXo" / "util"
DOS_DIR      = EXODOS_ROOT / "eXo" / "eXoDOS" / "!dos"
EXO_LIB_SH   = UTIL_DIR / "exo_lib.sh"
EXO_LIB_XML  = "../eXo/util/exo_lib.sh"   # relative from xml/
EXO_LIB_UTIL = "exo_lib.sh"               # relative from eXo/util/
EXO_LIB_LANG = "../exo_lib.sh"            # relative from eXo/util/!languagepacks/

# Directories containing .bsh-only scripts (no .msh counterpart) that need
# conversion to unified .sh + thin .command wrappers (Mode 5).
# Each entry is (directory_path, exo_lib_rel_from_that_dir).
BSHONLY_TARGETS = [
    (EXODOS_ROOT / "eXo" / "emulators" / "dosbox",                        "../../util/exo_lib.sh"),
    (EXODOS_ROOT / "eXo" / "emulators" / "dosbox" / "!languagepacks",     "../../../util/exo_lib.sh"),
    (EXODOS_ROOT / "eXo" / "emulators" / "dosbox" / "GunStick_dosbox",    "../../../util/exo_lib.sh"),
    (EXODOS_ROOT / "eXo" / "Update",                                       "../util/exo_lib.sh"),
    (EXODOS_ROOT / "eXo" / "util" / "Sumatra",                            "../exo_lib.sh"),
]

DRY_RUN = "--dry-run" in sys.argv


def _parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--dry-run", action="store_true",
                        help="Print what would be done without writing any files")
    parser.add_argument("--game-bsh", action="store_true",
                        help="Mode A: replace per-game .bsh/.command with thin exo_launch/exo_install wrappers")
    parser.add_argument("--strip-exc", action="store_true",
                        help="Mode B: strip Linux boilerplate from exception.bsh files")
    parser.add_argument("--xml", action="store_true",
                        help="Mode 1: merge .bsh/.msh pairs in xml/ into unified .sh files")
    parser.add_argument("--util", action="store_true",
                        help="Mode 2: merge .bsh/.msh pairs in eXo/util/ (and !languagepacks/) into unified .sh files")
    parser.add_argument("--exceptions", action="store_true",
                        help="Mode 3: transform exception.bsh files to exception.sh with macOS support")
    parser.add_argument("--launch", action="store_true",
                        help="Mode 4: update launch.bsh and launch.msh to look for exception.sh first")
    parser.add_argument("--bshonly", action="store_true",
                        help="Mode 5: convert .bsh-only scripts in dosbox/, Update/, Sumatra/ to unified .sh")
    parser.add_argument("--purge-backups", action="store_true",
                        help="Remove all .bsh.bak/.command.bak backup files from previous runs (prompts first)")
    return parser.parse_args()


_args = _parse_args()
DRY_RUN = _args.dry_run

_ANY_MODE = any([_args.game_bsh, _args.strip_exc, _args.xml, _args.util,
                 _args.exceptions, _args.launch, _args.bshonly])
_ALL           = not _ANY_MODE and not _args.purge_backups
RUN_GAME_BSH   = _ALL or _args.game_bsh
RUN_STRIP_EXC  = _ALL or _args.strip_exc
RUN_XML        = _ALL or _args.xml
RUN_UTIL       = _ALL or _args.util
RUN_EXCEPTIONS = _ALL or _args.exceptions
RUN_LAUNCH     = _ALL or _args.launch
RUN_BSHONLY    = _ALL or _args.bshonly
RUN_PURGE      = _args.purge_backups


# Per-game wrapper content (modes A)
_LAUNCH_WRAPPER = (
    '#!/usr/bin/env bash\n'
    'source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/util/exo_lib.sh"\n'
    'exo_launch\n'
)
_INSTALL_WRAPPER = (
    '#!/usr/bin/env bash\n'
    'source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/util/exo_lib.sh"\n'
    'exo_install\n'
)

# exception.bsh header after boilerplate is stripped (mode B)
_EXC_STRIPPED_HEADER = (
    '#!/usr/bin/env bash\n'
    '# exception.bsh — game-specific launch override.\n'
    '# Sourced by launch.msh/launch.bsh; exo_lib.sh context already loaded.\n'
    '\n'
)

# Thin .command wrapper — macOS Finder entry point that sources the .sh (mode 5)
_COMMAND_THIN = (
    '#!/usr/bin/env bash\n'
    'cd "$(dirname "$BASH_SOURCE")"\n'
    'source "./{sh_name}"\n'
)


# Generic helpers

def make_thin_command(sh_name):
    """Return content for a thin .command wrapper that sources the given .sh file."""
    return _COMMAND_THIN.replace("{sh_name}", sh_name)


def apply_sed_fix(text):
    """Replace bare 'sed' calls with '$_SED' for cross-platform compatibility.

    $_SED is defined by exo_lib.sh as gsed on macOS (GNU-compatible) and sed on Linux,
    so scripts that use GNU sed flags (-i -e) will work on both platforms.
    """
    return re.sub(r'\bsed\b', '$_SED', text)


def _read_line():
    """Read a line from stdin, handling macOS terminals where Enter sends CR (^M).

    Root cause: when ICRNL is off in the terminal, the OS never translates CR→NL,
    so canonical mode never sees a line terminator and readline() blocks forever.
    Fix: temporarily force ICRNL on via termios, then restore original settings.
    """
    if _HAS_TERMIOS and sys.stdin.isatty():
        fd = sys.stdin.fileno()
        old = _termios.tcgetattr(fd)
        try:
            new = _termios.tcgetattr(fd)
            new[0] |= _termios.ICRNL   # force CR → NL translation
            _termios.tcsetattr(fd, _termios.TCSANOW, new)
            return sys.stdin.readline().rstrip("\r\n")
        finally:
            _termios.tcsetattr(fd, _termios.TCSADRAIN, old)
    return sys.stdin.readline().rstrip("\r\n")


def ask(prompt, default=True):
    tag = "Y/n" if default else "y/N"
    while True:
        sys.stdout.write(f"\n{prompt} [{tag}]: ")
        sys.stdout.flush()
        ans = _read_line().strip().lower()
        if not ans:
            return default
        if ans in ("y", "yes"):
            return True
        if ans in ("n", "no"):
            return False
        print("Please enter y or n.")


def find_fi(lines, start):
    depth = 0
    for i in range(start, len(lines)):
        s = lines[i].strip()
        if re.match(r"^if\b", s):
            depth += 1
        elif s == "fi":
            depth -= 1
            if depth == 0:
                return i
    return -1


def find_closing_brace(lines, start):
    depth = 0
    for i in range(start, len(lines)):
        s = lines[i].strip()
        if s == "{":
            depth += 1
        elif s == "}":
            depth -= 1
            if depth == 0:
                return i
    return -1


def indent_block(text, spaces=4):
    prefix = " " * spaces
    return "".join(prefix + ln for ln in text.splitlines(keepends=True))


def backup(files, backup_dir):
    backup_dir.mkdir(parents=True, exist_ok=True)
    for src in files:
        if src.exists():
            dst = backup_dir / src.name
            shutil.copy2(src, dst)
            print(f"    backed up  {src.name}  ->  {dst}")


# XML/util boilerplate pair parser

def parse(path, is_bsh):
    lines  = path.read_text(encoding="utf-8").splitlines(keepends=True)
    oskey  = "darwin" if is_bsh else "linux-gnu"

    rstart = next((i for i, ln in enumerate(lines) if f'"$OSTYPE" == "{oskey}' in ln), None)
    if rstart is None:
        raise ValueError(f"{path.name}: OS redirect for '{oskey}' not found")
    rend = find_fi(lines, rstart)
    if rend == -1:
        raise ValueError(f"{path.name}: unmatched fi for OS redirect")

    header = "".join(lines[:rstart])
    rem    = lines[rend + 1:]

    gstart = next((i for i, ln in enumerate(rem) if ln.strip() == "function goto"), None)
    if gstart is None:
        raise ValueError(f"{path.name}: 'function goto' not found")
    gend = find_closing_brace(rem, gstart)
    if gend == -1:
        raise ValueError(f"{path.name}: closing brace of goto not found")

    dcstart = next(
        (i for i, ln in enumerate(rem[gend + 1:], start=gend + 1)
         if ln.strip() == "function dynchoice"), None
    )
    if dcstart is None:
        raise ValueError(f"{path.name}: 'function dynchoice' not found")
    dcend = find_closing_brace(rem, dcstart)
    if dcend == -1:
        raise ValueError(f"{path.name}: closing brace of dynchoice not found")

    after = dcend + 1
    while after < len(rem) and rem[after].strip() == "":
        after += 1

    errstart = next(
        (i for i, ln in enumerate(rem[after:], start=after)
         if 'if [ $missingDependencies == "yes"' in ln), None
    )
    if errstart is None:
        raise ValueError(f"{path.name}: missingDependencies error block not found")

    dep_checks = "".join(rem[after:errstart])
    errend = find_fi(rem, errstart)
    if errend == -1:
        raise ValueError(f"{path.name}: unmatched fi for error block")

    return {
        "header":      header,
        "dep_checks":  dep_checks,
        "error_block": "".join(rem[errstart:errend + 1]),
        "functional":  "".join(rem[errend + 1:]),
    }


def generate_sh(bsh, msh, exo_lib_rel):
    linux_dep = indent_block(bsh["dep_checks"].strip())
    mac_dep   = indent_block(msh["dep_checks"].strip())
    return (
        bsh["header"]
        + "# Load shared utilities: goto, dynchoice, _SED, bash-version guard, PATH\n"
        + f'source "$scriptDir/{exo_lib_rel}"\n\n'
        + "# Dependency checks\n"
        + 'if [[ "$OSTYPE" == "linux-gnu"* ]]\nthen\n'
        + linux_dep + "\n"
        + 'elif [[ "$OSTYPE" == "darwin"* ]]\nthen\n'
        + mac_dep + "\n"
        + "fi\n\n"
        + bsh["error_block"].strip() + "\n\n"
        + bsh["functional"].strip() + "\n"
    )


def generate_sh_bshonly(bsh, exo_lib_rel):
    """Generate a unified .sh from a .bsh file that has no .msh counterpart.

    Uses the Linux dep_checks for both platforms (most tools — flatpak, curl,
    python3, sed, unzip, wget — are expected on both).  The functional content
    has 'sed' replaced with '$_SED' so it works with both GNU sed (Linux) and
    gsed/sed on macOS after exo_lib.sh is sourced.

    If the script references 'options_linux.conf' a NOTE is printed so the
    author can add the macOS-specific options_macos.conf path manually.
    """
    dep = indent_block(bsh["dep_checks"].strip())
    functional = apply_sed_fix(bsh["functional"].strip())
    return (
        bsh["header"]
        + "# Load shared utilities: goto, dynchoice, _SED, bash-version guard, PATH\n"
        + f'source "$scriptDir/{exo_lib_rel}"\n\n'
        + "# Dependency checks\n"
        + 'if [[ "$OSTYPE" == "linux-gnu"* ]]\nthen\n'
        + dep + "\n"
        + 'elif [[ "$OSTYPE" == "darwin"* ]]\nthen\n'
        + dep + "\n"
        + "fi\n\n"
        + bsh["error_block"].strip() + "\n\n"
        + functional + "\n"
    )


def update_command(path):
    text = path.read_text(encoding="utf-8")
    text = text.replace('%.command}.bsh"', '%.command}.sh"')
    text = text.replace('%.command}.msh"', '%.command}.sh"')
    return text


def process_pair(bsh_path, msh_path, backup_dir, exo_lib_rel):
    base    = bsh_path.stem
    sh_path = bsh_path.with_suffix(".sh")
    cmd_path = bsh_path.with_suffix(".command")

    print(f"\n{'':->60}")
    print(f"  {base}  ({bsh_path.parent.name})")
    print(f"{'':->60}")

    try:
        bsh = parse(bsh_path, is_bsh=True)
        msh = parse(msh_path, is_bsh=False)
    except ValueError as exc:
        print(f"  ERROR: {exc}")
        return False

    sh_content  = generate_sh(bsh, msh, exo_lib_rel)
    cmd_content = update_command(cmd_path) if cmd_path.exists() else None

    orig_lines = bsh_path.read_text().count("\n") + msh_path.read_text().count("\n")
    print(f"  {bsh_path.name} + {msh_path.name}  ({orig_lines} lines combined)")
    print(f"  -> {sh_path.name}  ({sh_content.count(chr(10))} lines)")
    if cmd_content is not None:
        orig_cmd = cmd_path.read_text(encoding="utf-8")
        changed  = sum(1 for a, b in zip(orig_cmd.splitlines(), cmd_content.splitlines()) if a != b)
        print(f"  Command : {cmd_path.name}  ({changed} line(s) updated)")

    if DRY_RUN:
        print("  [dry-run] No files modified.")
        return True
    if not ask(f"  Apply changes for '{base}'?"):
        print("  Skipped.")
        return True

    to_backup = [bsh_path, msh_path] + ([cmd_path] if cmd_path.exists() else [])
    backup(to_backup, backup_dir)
    sh_path.write_text(sh_content, encoding="utf-8")
    sh_path.chmod(0o755)
    print(f"  OK  Written  {sh_path.name}")
    if cmd_content is not None and cmd_path.exists():
        cmd_path.write_text(cmd_content, encoding="utf-8")
        print(f"  OK  Updated  {cmd_path.name}")
    bsh_path.unlink()
    msh_path.unlink()
    print(f"  OK  Deleted  {bsh_path.name}  and  {msh_path.name}")
    return True


# Mode A: per-game .bsh/.command → .sh thin wrappers + .command macOS launchers
#
# Each game directory contains:
#   "Game Name (Year).bsh"   — Linux/macOS launch script (→ becomes .sh)
#   "Game Name (Year).command" — macOS Finder launcher   (→ thin wrapper sourcing .sh)
#   "install.bsh"            — install script            (→ becomes install.sh)
#   "install.command"        — macOS Finder installer    (→ thin wrapper sourcing install.sh)
#   "exception.bsh"          — game-specific override    (skipped; Mode B/3 handles it)
#
# "Done" state: game.sh exists with correct content, game.bsh absent, game.command
# is the correct thin wrapper.

def run_game_bsh(backup_dir):
    print("\n" + "=" * 60)
    print("  MODE A -- per-game .bsh → .sh + .command thin-wrapper transform")
    print("=" * 60)
    if not DOS_DIR.is_dir():
        print(f"  ERROR: {DOS_DIR} not found.")
        return 0

    # to_do entries: (bsh_path_or_None, sh_path, sh_content, cmd_path, cmd_content)
    to_do = []
    skip_done = skip_exc = skip_extras = skip_other = 0

    for gamedir in sorted(DOS_DIR.iterdir()):
        if not gamedir.is_dir():
            continue

        # Count files in Extras/ etc. (different call depth — skip those)
        for subdir in gamedir.iterdir():
            if subdir.is_dir():
                for sf in subdir.iterdir():
                    if not sf.name.startswith("._") and sf.suffix in (".bsh", ".command"):
                        skip_extras += 1

        # Collect relevant .bsh files (source of truth; .command derived from them)
        for bsh in sorted(gamedir.iterdir()):
            if bsh.name.startswith("._") or bsh.suffix != ".bsh":
                continue
            if bsh.name == "exception.bsh":
                skip_exc += 1
                continue

            if bsh.name == "install.bsh":
                sh_name    = "install.sh"
                sh_content = _INSTALL_WRAPPER
            elif bsh.name.endswith(").bsh"):
                sh_name    = bsh.stem + ".sh"
                sh_content = _LAUNCH_WRAPPER
            else:
                skip_other += 1
                continue

            sh_path  = gamedir / sh_name
            cmd_path = gamedir / (bsh.stem + ".command")
            cmd_content = make_thin_command(sh_name)

            # Already fully done?
            sh_ok  = sh_path.exists()  and sh_path.read_text("utf-8")  == sh_content
            cmd_ok = (not cmd_path.exists()) or cmd_path.read_text("utf-8") == cmd_content
            bsh_gone = not bsh.exists()
            if sh_ok and cmd_ok and bsh_gone:
                skip_done += 1
                continue

            to_do.append((bsh, sh_path, sh_content, cmd_path, cmd_content))

    print(f"\n  To transform: {len(to_do)}  |  "
          f"already done: {skip_done}, exception: {skip_exc}, "
          f"extras: {skip_extras}, other: {skip_other}")

    if not to_do:
        print("  Nothing to do.")
        return 0

    if DRY_RUN:
        for bsh, sh, _, cmd, _ in to_do[:5]:
            print(f"    {bsh.parent.name}/{bsh.name} → {sh.name}  +  {cmd.name}")
        if len(to_do) > 5:
            print(f"    ... and {len(to_do) - 5} more")
        print(f"\n  [dry-run] game-bsh done -- {len(to_do)} would be transformed.")
        return len(to_do)

    if not ask(f"Transform {len(to_do)} per-game script pairs?"):
        print("  Skipped.")
        return 0

    ok = errors = 0
    for bsh, sh_path, sh_content, cmd_path, cmd_content in to_do:
        try:
            # Back up .bsh if not already backed up
            bak = bsh.with_suffix(bsh.suffix + ".bak")
            if not bak.exists():
                shutil.copy2(bsh, bak)

            # Write the unified .sh
            sh_path.write_text(sh_content, encoding="utf-8")
            sh_path.chmod(sh_path.stat().st_mode | 0o111)

            # Write the thin .command wrapper (back up if needed)
            if cmd_path.exists():
                cmd_bak = cmd_path.with_suffix(cmd_path.suffix + ".bak")
                if not cmd_bak.exists():
                    shutil.copy2(cmd_path, cmd_bak)
            cmd_path.write_text(cmd_content, encoding="utf-8")
            cmd_path.chmod(cmd_path.stat().st_mode | 0o111)

            # Remove the now-superseded .bsh
            bsh.unlink()
            ok += 1
        except Exception as exc:
            print(f"  ERROR  {bsh}: {exc}")
            errors += 1

    print(f"\n  game-bsh done -- {ok} transformed, {errors} errors.")
    return ok


# Mode B: strip boilerplate from exception.bsh files

def run_strip_boilerplate(backup_dir):
    print("\n" + "=" * 60)
    print("  MODE B -- strip boilerplate from exception.bsh files")
    print("=" * 60)
    if not DOS_DIR.is_dir():
        print(f"  ERROR: {DOS_DIR} not found.")
        return 0

    to_do = []   # (path, stripped_content)
    skip_done = skip_no_depcheck = skip_empty = 0

    for gamedir in sorted(DOS_DIR.iterdir()):
        if not gamedir.is_dir():
            continue
        exc = gamedir / "exception.bsh"
        if not exc.exists():
            continue

        content = exc.read_text(encoding="utf-8", errors="replace")
        if "missingDependencies" not in content:
            # Already stripped (or never had it)
            skip_done += 1
            continue

        lines = content.splitlines()

        dep_if_idx = next(
            (i for i, ln in enumerate(lines)
             if ln.strip() == 'if [ $missingDependencies == "yes" ]'),
            None,
        )
        if dep_if_idx is None:
            skip_no_depcheck += 1
            continue

        dep_fi_idx = next(
            (i for i in range(dep_if_idx + 1, len(lines))
             if lines[i].strip() == "fi"),
            None,
        )
        if dep_fi_idx is None:
            skip_no_depcheck += 1
            continue

        unique = lines[dep_fi_idx + 1:]
        while unique and not unique[0].strip():
            unique.pop(0)
        if not unique:
            skip_empty += 1
            continue

        to_do.append((exc, _EXC_STRIPPED_HEADER + "\n".join(unique) + "\n"))

    print(f"\n  To strip: {len(to_do)}  |  "
          f"already done: {skip_done}, no depcheck: {skip_no_depcheck}, empty: {skip_empty}")

    if not to_do:
        print("  Nothing to do.")
        return 0

    if DRY_RUN:
        print(f"\n  [dry-run] strip-exc done -- {len(to_do)} would be stripped.")
        return len(to_do)

    if not ask(f"Strip boilerplate from {len(to_do)} exception.bsh files?"):
        print("  Skipped.")
        return 0

    ok = errors = 0
    for exc, new_content in to_do:
        try:
            bak = exc.with_suffix(".bsh.bak")
            if not bak.exists():
                shutil.copy2(exc, bak)
            exc.write_text(new_content, encoding="utf-8")
            ok += 1
        except Exception as e:
            print(f"  ERROR  {exc}: {e}")
            errors += 1

    print(f"\n  strip-exc done -- {ok} stripped, {errors} errors.")
    return ok


# Mode 1: xml/ pairs

def run_xml(backup_dir):
    print("\n" + "=" * 60)
    print("  MODE 1 -- xml/ pairs")
    print("=" * 60)
    if not XML_DIR.is_dir():
        print(f"  ERROR: {XML_DIR} not found.")
        return 0

    pairs = [(b, b.with_suffix(".msh")) for b in sorted(XML_DIR.glob("*.bsh"))
             if b.with_suffix(".msh").exists()]
    if not pairs:
        print("  No .bsh/.msh pairs found in xml/")
        return 0

    print(f"\n  Pairs found ({len(pairs)}):")
    for b, m in pairs:
        print(f"    {b.name}  +  {m.name}  ->  {b.stem}.sh")

    if not DRY_RUN and not ask("Proceed with xml/ pairs?"):
        return 0

    ok = sum(process_pair(b, m, backup_dir / "xml", EXO_LIB_XML) for b, m in pairs)
    print(f"\n  xml/ done -- {ok}/{len(pairs)} pair(s).")
    return ok


# Mode 2: eXo/util/ pairs (including !languagepacks subdir)

UTIL_SKIP    = {"launch.bsh", "launch.msh"}
UTIL_BSHONLY = {"eXoMerge.bsh", "install_dependencies.bsh", "Setup eXoDOS.bsh"}

# Subdirectories of UTIL_DIR that contain .bsh/.msh pairs to merge.
# Maps subdir name → exo_lib.sh path relative to that subdir.
UTIL_SUBDIRS = {
    "!languagepacks": EXO_LIB_LANG,
}


def run_util(backup_dir):
    print("\n" + "=" * 60)
    print("  MODE 2 -- eXo/util/ pairs (including subdirectories)")
    print("=" * 60)

    # Build a flat list of (bsh, msh, exo_lib_rel, bak_subdir) tuples.
    all_pairs = []

    # Main util/ dir
    for b in sorted(UTIL_DIR.glob("*.bsh")):
        if b.name.startswith("._"):
            continue
        if b.name in UTIL_SKIP or b.name in UTIL_BSHONLY:
            continue
        m = b.with_suffix(".msh")
        if m.exists():
            all_pairs.append((b, m, EXO_LIB_UTIL, backup_dir / "util"))

    # Subdirectories
    for subdir_name, exo_lib_rel in UTIL_SUBDIRS.items():
        subdir = UTIL_DIR / subdir_name
        if not subdir.is_dir():
            continue
        for b in sorted(subdir.glob("*.bsh")):
            if b.name.startswith("._"):
                continue
            m = b.with_suffix(".msh")
            if m.exists():
                all_pairs.append((b, m, exo_lib_rel, backup_dir / "util" / subdir_name))

    if not all_pairs:
        print("  No .bsh/.msh pairs found in eXo/util/ or its subdirectories")
        return 0

    print(f"\n  Pairs found ({len(all_pairs)}):")
    for b, m, _, _ in all_pairs:
        rel = b.relative_to(UTIL_DIR)
        print(f"    {rel.parent}/{b.name}  +  {m.name}  ->  {b.stem}.sh")

    if not DRY_RUN and not ask("Proceed with util/ pairs?"):
        return 0

    ok = 0
    for b, m, exo_lib_rel, bak_dir in all_pairs:
        if process_pair(b, m, bak_dir, exo_lib_rel):
            ok += 1
            if b.name == "install.bsh" and b.parent == UTIL_DIR and not DRY_RUN:
                _patch_exo_lib_install_ref(backup_dir)
    print(f"\n  util/ done -- {ok}/{len(all_pairs)} pair(s).")
    return ok


def _patch_exo_lib_install_ref(backup_dir):
    old = 'eval source "./util/install.bsh"'
    new = 'eval source "./util/install.sh"'
    text = EXO_LIB_SH.read_text(encoding="utf-8")
    if old not in text:
        print("  (exo_lib.sh: install.bsh ref not found -- already updated?)")
        return
    backup([EXO_LIB_SH], backup_dir / "util")
    EXO_LIB_SH.write_text(text.replace(old, new), encoding="utf-8")
    print("  OK  Updated exo_lib.sh: install.bsh -> install.sh")


# Mode 3: exception.bsh -> exception.sh

LABEL_RE      = re.compile(r"^:\s+(\S+)\s*$")
EVAL_DB_RE    = re.compile(r"eval.*\$\{dosbox\}", re.DOTALL)
COND_EVAL_RE  = re.compile(r"(\[.*?\])\s*&&\s*(eval\s+\".+)")


def split_into_sections(lines):
    """Return (preamble_lines, [(label_str, section_lines), ...])."""
    label_positions = []
    for i, ln in enumerate(lines):
        m = LABEL_RE.match(ln.rstrip("\n"))
        if m:
            label_positions.append((i, m.group(1)))
    if not label_positions:
        return lines, []
    preamble = lines[: label_positions[0][0]]
    sections = []
    for j, (pos, label) in enumerate(label_positions):
        end = label_positions[j + 1][0] if j + 1 < len(label_positions) else len(lines)
        sections.append((label, lines[pos:end]))
    return preamble, sections


def detect_launch_type(lines):
    text = "".join(lines)
    if re.search(r"flatpak run com\.retro_exo\.scummvm", text):
        return "scummvm"
    # Wine wrapping DOSBox with a mouse helper — e.g. Dune2MouseHelper.exe,
    # SkyNETMouseHelper.exe, WarcraftMouseHelper.exe.  These are playable on
    # macOS via DOSBox Staging with per-game mouse tuning (dosbox_macos.conf).
    if "flatpak run com.retro_exo.wine" in text and "MouseHelper.exe" in text:
        return "wine_dosbox_mouse"
    if "flatpak run com.retro_exo.wine" in text:
        return "wine"
    if EVAL_DB_RE.search(text):
        return "dosbox"
    if "86Box-Linux-x86_64" in text:
        return "86box_linux"
    return "other"


def extract_conf_file(eval_line):
    m = re.search(r"\)/([^\"/\\]+\.conf)\\\"", eval_line)
    return m.group(1) if m else "dosbox_linux.conf"


def extract_extra_flags(eval_line):
    m = re.search(r"-nomenu\s+(.*)", eval_line.rstrip())
    if not m:
        return ""
    flags = re.sub(r"\s*-exit\b", "", m.group(1)).strip()
    return flags


def fix_sed_line(line, gamedir_name):
    # Replace sed with $_SED at start of command
    line = re.sub(r"^(\s*)sed\b", r"\1$_SED", line)
    # Replace hardcoded game-dir path: "./eXoDOS/"\!"dos/GAMEDIR/" -> "${DOS_DIR}/GAMEDIR/"
    # Replace hardcoded game-dir path: "./eXoDOS/"\!"dos/GAMEDIR/" -> "${DOS_DIR}/GAMEDIR/"
    # The file literally contains: "  (quote) + ./eXoDOS/ + " (quote) + \ + ! + " (quote) + dos/
    line = re.sub(
        r'"./eXoDOS/"\\!"dos/' + re.escape(gamedir_name) + "/",
        '"${DOS_DIR}/' + gamedir_name + "/",
        line,
    )
    return line


def generate_mac_dosbox(exec_lines, gamedir_name):
    # Collect all (condition_str | None, eval_line) pairs
    cond_evals = []
    sed_lines  = []
    for ln in exec_lines:
        stripped = ln.strip()
        m = COND_EVAL_RE.match(stripped)
        if m:
            cond_evals.append((m.group(1), m.group(2)))
        elif EVAL_DB_RE.match(stripped):
            cond_evals.append((None, stripped))
        elif re.match(r"\s*(\[.*\]\s*&&\s*)?sed\s+-i", ln):
            sed_lines.append(ln)

    if not cond_evals:
        return ["# TODO: could not parse DOSBox eval line -- manual review needed\n"]

    def _exec_block(eval_line):
        """Return lines for exec "${EXO_EMULATOR_CMD[@]}" with no extra indent."""
        conf_file   = extract_conf_file(eval_line)
        extra_flags = extract_extra_flags(eval_line)
        last = f'    -nomenu -noconsole{" " + extra_flags if extra_flags else ""}\n'
        return [
            'exec "${EXO_EMULATOR_CMD[@]}" \\\n',
            f'    -conf "${{DOS_DIR}}/${{gamedir}}/{conf_file}" \\\n',
            '    -conf "$EXO_DIR/emulators/dosbox/options_macos.conf" \\\n',
            last,
        ]

    mac = ['cd "$EXO_DIR"\n']
    for ln in sed_lines:
        mac.append(fix_sed_line(ln, gamedir_name))

    if len(cond_evals) == 1:
        # Single (possibly unconditional) eval — existing behaviour
        mac.extend(_exec_block(cond_evals[0][1]))
    else:
        # Multiple conditional eval lines → if / elif|else / fi block.
        # Lines inside each branch get one extra level of indent (4 spaces)
        # because _wrap_os will add another 4 on top of that.
        for i, (cond, eval_line) in enumerate(cond_evals):
            if cond is None:
                mac.append("else\n")
            elif i == 0:
                mac.append(f"if {cond}; then\n")
            else:
                # Use 'else' when this condition is the negation of the first
                first = cond_evals[0][0] or ""
                negated = re.sub(r"^\[ ", "[ ! ", first)
                mac.append("else\n" if negated == cond else f"elif {cond}; then\n")
            for ln in _exec_block(eval_line):
                mac.append("    " + ln)
        mac.append("fi\n")

    return mac


def generate_mac_scummvm(exec_lines):
    for ln in exec_lines:
        m = re.search(r"flatpak run com\.retro_exo\.scummvm-\S+\s+(.*)", ln)
        if m:
            return [f"scummvm {m.group(1).strip()}\n"]
    return ["# TODO: could not parse ScummVM launch -- manual review needed\n"]


def generate_mac_wine_dosbox_mouse(exec_lines, gamedir_name):
    """Generate a macOS DOSBox Staging launch for Wine+MouseHelper.exe exceptions.

    Extracts the per-game dosbox conf from the wine command line and builds a
    standard three-conf Staging launch.  A dosbox_macos.conf with tuned [mouse]
    settings must exist in the game directory (mouse_capture, raw_mouse_input,
    mouse_sensitivity) — it is applied last so it overrides any linux-only values.
    """
    # Try to extract the per-game conf filename from the wine command.
    conf_file = "dosbox_linux.conf"
    for ln in exec_lines:
        m = re.search(r'-conf\s+"?\.?/eXoDOS/[^/]+/dosbox[^/]*\.conf"?', ln)
        if m:
            conf_file = re.search(r'(dosbox[^/]*\.conf)', m.group(0)).group(1)
            break

    return [
        'cd "$EXO_DIR"\n',
        '"${EXO_EMULATOR_CMD[@]}" \\\n',
        f'    -conf "${{DOS_DIR}}/${{gamedir}}/{conf_file}" \\\n',
        '    -conf "$EXO_DIR/emulators/dosbox/options_macos.conf" \\\n',
        '    -conf "$DOS_DIR/$gamedir/dosbox_macos.conf" \\\n',
        '    -nomenu -noconsole\n',
        'rm -f stdout.txt stderr.txt\n',
        'compgen -G \'glide.*\' &>/dev/null && rm -f glide.*\n',
        '[[ -f "$DOSBASE/CWSDPMI.swp" ]] && rm -f "$DOSBASE/CWSDPMI.swp"\n',
    ]



def _find_goto_end(body):
    for i in range(len(body) - 1, -1, -1):
        if "goto end" in body[i]:
            return i
    return len(body)


def _wrap_os(label_line, linux_lines, mac_lines, goto_line=None):
    out = [label_line] if label_line else []
    out.append('if [[ "$OSTYPE" == "linux-gnu"* ]]; then\n')
    out.extend("    " + ln for ln in linux_lines)
    out.append('elif [[ "$OSTYPE" == "darwin"* ]]; then\n')
    out.extend("    " + ln for ln in mac_lines)
    out.append("fi\n")
    if goto_line:
        out.append(goto_line)
    return out


def transform_exception(bsh_path, msh_path=None, gamedir_name=""):
    lines = bsh_path.read_text(encoding="utf-8").splitlines(keepends=True)

    msh_sections = {}
    if msh_path and msh_path.exists():
        msh_lines = msh_path.read_text(encoding="utf-8").splitlines(keepends=True)
        _, msh_sects = split_into_sections(msh_lines)
        msh_sections = {lbl: sl for lbl, sl in msh_sects}

    preamble, sections = split_into_sections(lines)

    # Separate leading header (shebang/comments) from executable code
    header_end = 0
    for i, ln in enumerate(preamble):
        s = ln.strip()
        if s and not s.startswith("#"):
            header_end = i
            break
    else:
        header_end = len(preamble)

    preamble_header = preamble[:header_end]
    preamble_exec   = preamble[header_end:]

    def fix_header(lns):
        return [
            ln.replace("exception.bsh --", "exception.sh --")
              .replace("# exception.bsh", "# exception.sh")
              .replace("Sourced by launch.msh/launch.bsh", "Sourced by launch.sh/launch.bsh/launch.msh")
            for ln in lns
        ]

    out = fix_header(preamble_header)

    if preamble_exec:
        ptype = detect_launch_type(preamble_exec)
        if ptype in ("scummvm", "wine", "wine_dosbox_mouse", "dosbox", "86box_linux"):
            ge        = _find_goto_end(preamble_exec)
            exec_part = preamble_exec[:ge]
            goto_line = preamble_exec[ge] if ge < len(preamble_exec) else None
            if ptype == "scummvm":
                mac = generate_mac_scummvm(exec_part)
            elif ptype == "wine_dosbox_mouse":
                mac = generate_mac_wine_dosbox_mouse(exec_part, gamedir_name)
            elif ptype == "wine":
                mac = ["return 1\n"]
            elif ptype == "dosbox":
                mac = generate_mac_dosbox(exec_part, gamedir_name)
            else:
                mac = ["return 1\n"]
            out.extend(_wrap_os(None, exec_part, mac, goto_line))
        else:
            out.extend(preamble_exec)

    for label, sect_lines in sections:
        label_line = sect_lines[0]
        body       = sect_lines[1:]

        if label == "end":
            out.append(label_line)
            out.extend(body)
            continue

        if label in msh_sections:
            msh_body = msh_sections[label][1:]
            bsh_ge   = _find_goto_end(body)
            msh_ge   = _find_goto_end(msh_body)
            linux_p  = body[:bsh_ge]
            mac_p    = msh_body[:msh_ge]
            goto     = body[bsh_ge] if bsh_ge < len(body) else None
            out.extend(_wrap_os(label_line, linux_p, mac_p, goto))
        else:
            stype     = detect_launch_type(body)
            ge        = _find_goto_end(body)
            exec_part = body[:ge]
            goto_line = body[ge] if ge < len(body) else None

            if stype == "dosbox":
                mac = generate_mac_dosbox(exec_part, gamedir_name)
                out.extend(_wrap_os(label_line, exec_part, mac, goto_line))
            elif stype == "scummvm":
                mac = generate_mac_scummvm(exec_part)
                out.extend(_wrap_os(label_line, exec_part, mac, goto_line))
            elif stype == "wine_dosbox_mouse":
                mac = generate_mac_wine_dosbox_mouse(exec_part, gamedir_name)
                out.extend(_wrap_os(label_line, exec_part, mac, goto_line))
            elif stype == "wine":
                mac = ["return 1\n"]
                out.extend(_wrap_os(label_line, exec_part, mac, goto_line))
            elif stype == "86box_linux":
                mac = ["return 1\n"]
                out.extend(_wrap_os(label_line, exec_part, mac, goto_line))
            else:
                out.append(label_line)
                out.extend(body)

    return "".join(out)


def run_exceptions(backup_dir):
    print("\n" + "=" * 60)
    print("  MODE 3 -- exception.bsh -> exception.sh")
    print("=" * 60)
    if not DOS_DIR.is_dir():
        print(f"  ERROR: {DOS_DIR} not found.")
        return 0

    bsh_files = sorted(
        p
        for gd in DOS_DIR.iterdir()
        if gd.is_dir()
        for p in [gd / "exception.bsh"]
        if p.exists()
    )
    has_msh = sum(1 for p in bsh_files if p.with_suffix(".msh").exists())
    print(f"\n  Found {len(bsh_files)} exception.bsh files ({has_msh} have matching .msh).")

    if not DRY_RUN and not ask(f"\nProceed with all {len(bsh_files)} exception files?"):
        return 0

    ok = errors = 0
    for bsh_path in bsh_files:
        gamedir_name = bsh_path.parent.name
        msh_path     = bsh_path.with_suffix(".msh")
        sh_path      = bsh_path.with_suffix(".sh")
        try:
            content = transform_exception(
                bsh_path,
                msh_path if msh_path.exists() else None,
                gamedir_name,
            )
        except Exception as exc:
            print(f"  ERROR  {gamedir_name}/exception.bsh: {exc}")
            errors += 1
            continue

        if DRY_RUN:
            ok += 1
            continue

        to_backup = [bsh_path] + ([msh_path] if msh_path.exists() else [])
        backup(to_backup, backup_dir / "exceptions" / gamedir_name)
        sh_path.write_text(content, encoding="utf-8")
        sh_path.chmod(0o755)
        bsh_path.unlink()
        if msh_path.exists():
            msh_path.unlink()
        ok += 1

    tag = "[dry-run] " if DRY_RUN else ""
    print(f"\n  {tag}exceptions done -- {ok} written, {errors} errors.")
    return ok


# Mode 4: update launch.bsh and launch.msh

_LAUNCH_BSH_OLD = '    local exc="$DOS_DIR/$gamedir/exception.bsh"'
_LAUNCH_BSH_NEW = (
    "    local exc\n"
    '    if [[ -f "$DOS_DIR/$gamedir/exception.sh" ]]; then\n'
    '        exc="$DOS_DIR/$gamedir/exception.sh"\n'
    '    elif [[ -f "$DOS_DIR/$gamedir/exception.bsh" ]]; then\n'
    '        exc="$DOS_DIR/$gamedir/exception.bsh"\n'
    "    fi"
)

_LAUNCH_MSH_OLD = '    local exc="$DOS_DIR/$gamedir/exception.msh"'
_LAUNCH_MSH_NEW = (
    "    local exc\n"
    '    if [[ -f "$DOS_DIR/$gamedir/exception.sh" ]]; then\n'
    '        exc="$DOS_DIR/$gamedir/exception.sh"\n'
    '    elif [[ -f "$DOS_DIR/$gamedir/exception.msh" ]]; then\n'
    '        exc="$DOS_DIR/$gamedir/exception.msh"\n'
    "    fi"
)

_IF_OLD = '    if [[ -f "$exc" ]]; then'
_IF_NEW = '    if [[ -n "$exc" ]] && [[ -f "$exc" ]]; then'


def run_launch(backup_dir):
    print("\n" + "=" * 60)
    print("  MODE 4 -- update launch.bsh and launch.msh")
    print("=" * 60)

    tasks = [
        (UTIL_DIR / "launch.bsh", _LAUNCH_BSH_OLD, _LAUNCH_BSH_NEW),
        (UTIL_DIR / "launch.msh", _LAUNCH_MSH_OLD, _LAUNCH_MSH_NEW),
    ]
    pending = []
    for path, old_exc, new_exc in tasks:
        if not path.exists():
            print(f"  {path.name}: not found")
            continue
        text = path.read_text(encoding="utf-8")
        if old_exc not in text:
            print(f"  {path.name}: exception lookup already updated")
            continue
        updated = text.replace(old_exc, new_exc).replace(_IF_OLD, _IF_NEW, 1)
        delta   = updated.count("\n") - text.count("\n")
        print(f"  {path.name}: +{delta} lines")
        pending.append((path, updated))

    if DRY_RUN:
        print("  [dry-run] No files modified.")
        return len(pending)
    if not pending:
        return 0
    if not ask("Apply launch script updates?"):
        print("  Skipped.")
        return 0

    backup([p for p, _ in pending], backup_dir / "util")
    for path, updated in pending:
        path.write_text(updated, encoding="utf-8")
        print(f"  OK  Updated  {path.name}")
    return len(pending)


# Mode 5: .bsh-only files → unified .sh + thin .command wrapper

def _is_toplevel_command_redirect(path):
    """Return True if the .bsh on macOS redirects to ../../*.command (UTIL_BSHONLY pattern).

    These files (eXoMerge.bsh, install_dependencies.bsh, Setup eXoDOS.bsh) have
    their macOS implementation in the top-level .command files which are excluded
    from processing, so we skip them here too.
    """
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
        # Match the specific pattern: source "...../../...%.bsh}.command"
        return bool(re.search(r'source.*\.\./\.\./.*BASH_SOURCE.*\.command', text))
    except OSError:
        return False


def process_bshonly(bsh_path, backup_dir, exo_lib_rel):
    """Convert a .bsh-only script to a unified .sh + thin .command wrapper."""
    base     = bsh_path.stem
    sh_path  = bsh_path.with_suffix(".sh")
    cmd_path = bsh_path.with_suffix(".command")

    print(f"\n{'':->60}")
    print(f"  {base}  ({bsh_path.parent.name})")
    print(f"{'':->60}")

    try:
        bsh = parse(bsh_path, is_bsh=True)
    except ValueError as exc:
        print(f"  ERROR: {exc}")
        return False

    sh_content  = generate_sh_bshonly(bsh, exo_lib_rel)
    cmd_content = make_thin_command(sh_path.name) if cmd_path.exists() else None

    orig_lines = bsh_path.read_text().count("\n")
    print(f"  {bsh_path.name}  ({orig_lines} lines)")
    print(f"  -> {sh_path.name}  ({sh_content.count(chr(10))} lines)")
    if cmd_content is not None:
        print(f"  -> {cmd_path.name}  (thin macOS wrapper)")
    if "options_linux.conf" in sh_content:
        print(f"  NOTE: references options_linux.conf — consider adding macOS options_macos.conf handling")

    if DRY_RUN:
        print("  [dry-run] No files modified.")
        return True
    if not ask(f"  Apply changes for '{base}'?"):
        print("  Skipped.")
        return True

    to_backup = [bsh_path] + ([cmd_path] if cmd_path.exists() else [])
    backup(to_backup, backup_dir)
    sh_path.write_text(sh_content, encoding="utf-8")
    sh_path.chmod(0o755)
    print(f"  OK  Written  {sh_path.name}")
    if cmd_content is not None and cmd_path.exists():
        cmd_path.write_text(cmd_content, encoding="utf-8")
        print(f"  OK  Updated  {cmd_path.name}")
    bsh_path.unlink()
    print(f"  OK  Deleted  {bsh_path.name}")
    return True


def run_bshonly(backup_dir):
    print("\n" + "=" * 60)
    print("  MODE 5 -- .bsh-only files -> unified .sh + thin .command")
    print("=" * 60)

    to_do = []   # (bsh_path, exo_lib_rel, bak_dir)

    for target_dir, exo_lib_rel in BSHONLY_TARGETS:
        if not target_dir.is_dir():
            print(f"  (skipping {target_dir} — not found)")
            continue
        for bsh_path in sorted(target_dir.glob("*.bsh")):
            if bsh_path.name.startswith("._"):
                continue
            if bsh_path.with_suffix(".msh").exists():
                # Has a .msh pair — handled by Mode 1/2, not here
                continue
            if _is_toplevel_command_redirect(bsh_path):
                # Redirects to top-level .command on macOS (UTIL_BSHONLY pattern)
                print(f"  (skipping {bsh_path.parent.name}/{bsh_path.name} — uses top-level .command on macOS)")
                continue
            rel = bsh_path.relative_to(EXODOS_ROOT)
            bak_dir = backup_dir / "bshonly" / bsh_path.parent.relative_to(EXODOS_ROOT)
            to_do.append((bsh_path, exo_lib_rel, bak_dir))

    if not to_do:
        print("  Nothing to do.")
        return 0

    print(f"\n  Files found ({len(to_do)}):")
    for bsh_path, _, _ in to_do:
        rel = bsh_path.relative_to(EXODOS_ROOT)
        has_cmd = bsh_path.with_suffix(".command").exists()
        print(f"    {rel}  {'(+ .command)' if has_cmd else ''}")

    if not DRY_RUN and not ask(f"\nProceed with all {len(to_do)} bsh-only files?"):
        print("  Skipped.")
        return 0

    ok = errors = 0
    for bsh_path, exo_lib_rel, bak_dir in to_do:
        try:
            if process_bshonly(bsh_path, bak_dir, exo_lib_rel):
                ok += 1
            else:
                errors += 1
        except Exception as exc:
            print(f"  ERROR  {bsh_path}: {exc}")
            errors += 1

    tag = "[dry-run] " if DRY_RUN else ""
    print(f"\n  {tag}bshonly done -- {ok} converted, {errors} errors.")
    return ok


# Standalone utility: purge backup files left by previous unify runs

def run_purge_backups():
    print("\n" + "=" * 60)
    print("  PURGE BACKUPS -- remove .bak files from previous unify runs")
    print("=" * 60)

    targets = []

    # In-place .bsh.bak and .command.bak throughout the entire tree.
    # Skip ._-prefixed files — macOS AppleDouble metadata artifacts that appear
    # in directory listings but aren't real backup files.
    for pattern in ("*.bsh.bak", "*.command.bak"):
        targets.extend(
            f for f in sorted(EXODOS_ROOT.rglob(pattern))
            if not f.name.startswith("._")
        )

    # launch.msh.bak in eXo/util/ (created by mode 4)
    launch_msh_bak = UTIL_DIR / "launch.msh.bak"
    if launch_msh_bak.exists():
        targets.append(launch_msh_bak)

    # _backup_<timestamp>/ directories at the root
    backup_dirs = sorted(EXODOS_ROOT.glob("_backup_*"))

    total_files = len(targets)
    total_dirs  = len(backup_dirs)

    if not targets and not backup_dirs:
        print("\n  Nothing to remove — no backup files found.")
        return 0

    print(f"\n  Found {total_files} .bak file(s) and {total_dirs} backup dir(s):")
    for f in targets[:10]:
        print(f"    {f.relative_to(EXODOS_ROOT)}")
    if total_files > 10:
        print(f"    ... and {total_files - 10} more .bak files")
    for d in backup_dirs:
        print(f"    {d.name}/  (directory)")

    if DRY_RUN:
        print(f"\n  [dry-run] purge-backups done -- {total_files} file(s) and {total_dirs} dir(s) would be removed.")
        return total_files + total_dirs

    if not ask(f"Permanently remove {total_files} .bak file(s) and {total_dirs} backup dir(s)?", default=False):
        print("  Skipped.")
        return 0

    removed = errors = 0
    for f in targets:
        try:
            f.unlink()
            removed += 1
        except Exception as exc:
            print(f"  ERROR removing {f}: {exc}")
            errors += 1
    for d in backup_dirs:
        try:
            # ignore_errors=True skips phantom macOS ._* metadata inside the dir
            shutil.rmtree(d, ignore_errors=True)
            if d.exists():
                print(f"  WARNING: could not fully remove {d.name}/  (some files may remain)")
            removed += 1
        except Exception as exc:
            print(f"  ERROR removing {d}: {exc}")
            errors += 1

    print(f"\n  purge-backups done -- {removed} item(s) removed, {errors} error(s).")
    return removed


# Main

def main():
    print("=" * 60)
    print("  eXoDOS Script Unifier  (comprehensive)")
    if DRY_RUN:
        print("  MODE: dry-run  (no files will be modified)")
    print("=" * 60)
    print(f"\n  Root : {EXODOS_ROOT}")
    ts         = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = EXODOS_ROOT / f"_backup_{ts}"
    print(f"  Backups : {backup_dir}" + ("  [skipped in dry-run]" if DRY_RUN else ""))

    total = 0
    if RUN_PURGE:
        total += run_purge_backups()
    if RUN_GAME_BSH:
        total += run_game_bsh(backup_dir)
    if RUN_STRIP_EXC:
        total += run_strip_boilerplate(backup_dir)
    if RUN_XML:
        total += run_xml(backup_dir)
    if RUN_UTIL:
        total += run_util(backup_dir)
    if RUN_EXCEPTIONS:
        total += run_exceptions(backup_dir)
    if RUN_LAUNCH:
        total += run_launch(backup_dir)
    if RUN_BSHONLY:
        total += run_bshonly(backup_dir)

    print("\n" + "=" * 60)
    print(f"  All done -- {total} item(s) processed.")


if __name__ == "__main__":
    main()
