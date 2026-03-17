#!/usr/bin/env bash
# exo_lib.sh — Shared functions for eXoDOS launch/install scripts.
# Source this file; do not execute it directly.
# All paths derived relative to this file's location — works on any mount point.

# ── PATH setup ────────────────────────────────────────────────────────────────
for _p in /opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /usr/local/sbin; do
    [[ -d "$_p" && ":$PATH:" != *":$_p:"* ]] && export PATH="$_p:$PATH"
done
unset _p

# ── Root detection ────────────────────────────────────────────────────────────
# EXO_UTIL  = directory containing this file  (eXo/util/)
# EXO_DIR   = eXo/
# EXO_ROOT  = collection root (parent of eXo/)
EXO_UTIL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXO_DIR="$(cd "$EXO_UTIL/.." && pwd)"
EXO_ROOT="$(cd "$EXO_DIR/.." && pwd)"
DOS_DIR="$EXO_DIR/eXoDOS/!dos"
DOSBASE="$EXO_DIR/eXoDOS"

# ── Bash version guard ────────────────────────────────────────────────────────
if [[ "${BASH_VERSINFO[0]:-0}" -lt 5 ]]; then
    printf "\n\033[1;31;47mBash 5+ required. Install via Homebrew: brew install bash\033[0m\n\n"
    exit 1
fi

# ── Cross-platform sed ────────────────────────────────────────────────────────
# Use gsed on macOS (GNU sed from Homebrew), BSD sed on Linux.
if [[ "$OSTYPE" == "darwin"* ]]; then
    _SED="$(command -v gsed 2>/dev/null || command -v sed)"
else
    _SED="$(command -v sed)"
fi

# ── goto ──────────────────────────────────────────────────────────────────────
# Usage: goto <label>  — evaluates everything after ": <label>" in the
# calling script, then exits.  The label line format is:  : <label>
function goto {
    local label="$1"
    local script="${BASH_SOURCE[1]}"
    local code
    code="$("$_SED" -n "/^: ${label}$/{:a;n;p;ba}" "$script")"
    eval "$code"
    exit 0
}

# ── dynchoice ─────────────────────────────────────────────────────────────────
# Usage: dynchoice <choices_string> <prompt>
# Sets $errorlevel to 1-N corresponding to the chosen option.
function dynchoice {
    local choices="$1" textpmt="$2"
    local n="${#choices}" upper="${choices^^}" lower="${choices,,}"
    while true; do
        read -r -p "$textpmt " choice
        local i
        for (( i=0; i<n; i++ )); do
            local u="${upper:$i:1}" l="${lower:$i:1}"
            if [[ "$choice" == [$u$l]* ]]; then
                errorlevel=$(( i+1 ))
                return
            fi
        done
        printf "Invalid input.\n"
    done
}

# ── Dependency check ──────────────────────────────────────────────────────────
# On macOS: verify Homebrew emulators and common tools are present.
# On Linux: dependency checking is handled by the existing launch.bsh logic.
function exo_check_deps {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        return 0
    fi
    local missing=()
    for t in dosbox-staging dosbox-x scummvm; do
        command -v "$t" &>/dev/null || missing+=("$t")
    done
    for t in aria2c curl python3 unzip wget; do
        command -v "$t" &>/dev/null || missing+=("$t")
    done
    if [[ "${#missing[@]}" -gt 0 ]]; then
        printf "\n\033[1;31;47mMissing dependencies: %s\033[0m\n\n" "${missing[*]}"
        printf "Install with:  brew install %s\n\n" "${missing[*]}"
        exit 1
    fi
}

# ── Emulator lookup ───────────────────────────────────────────────────────────
# Sets $EXO_EMULATOR to the command to run for the given game name.
# Uses dosbox_macos.txt on macOS (all architectures) and dosbox_linux.txt on Linux.
function exo_find_emulator {
    local name="$1"
    local dosindex=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        dosindex="$(grep -i "^${name}" "$EXO_UTIL/dosbox_macos.txt" 2>/dev/null | tail -1 | tr -d '\r')"
    else
        dosindex="$(grep -i "^${name}" "$EXO_UTIL/dosbox_linux.txt" 2>/dev/null | tail -1 | tr -d '\r')"
    fi
    EXO_EMULATOR="${dosindex#*:}"
    EXO_EMULATOR="${EXO_EMULATOR#*:}"
    [[ -z "$EXO_EMULATOR" ]] && EXO_EMULATOR="dosbox-staging"
    read -ra EXO_EMULATOR_CMD <<< "$EXO_EMULATOR"
}

# ── Context setup ─────────────────────────────────────────────────────────────
# Derives gamedir/gamename from the calling script's location.
# Pass the calling script path as $1 (determined by the top-level entry point).
function exo_setup_context {
    local calling_script="$1"
    local calling_dir
    calling_dir="$(cd "$(dirname "$calling_script")" && pwd)"
    gamedir="${calling_dir##*/}"
    local f
    for f in "$calling_dir"/*\).sh "$calling_dir"/*\).bsh; do
        [[ -f "$f" ]] || continue
        gamename="$(basename "${f%.*}")"
        break
    done
    indexname="${gamename::-7}"
    var="$calling_dir"
    export gamedir gamename indexname var
}

# ── 86Box lookup (macOS) ─────────────────────────────────────────────────────
# Sets EXO_86BOX_CMD to the 86Box binary path, or '' if not found.
function exo_find_86box {
    local locations=(
        "/Applications/86Box.app/Contents/MacOS/86Box"
        "$HOME/Applications/86Box.app/Contents/MacOS/86Box"
    )
    for loc in "${locations[@]}"; do
        if [[ -x "$loc" ]]; then
            EXO_86BOX_CMD="$loc"
            return 0
        fi
    done
    EXO_86BOX_CMD=""
    return 1
}

# ── macOS launch ──────────────────────────────────────────────────────────────
# ── Linux launch ──────────────────────────────────────────────────────────────
# ── Unified launch entry point ────────────────────────────────────────────────
# Called as the last line of every per-game .bsh after sourcing this library.
function exo_launch {
    local calling_script="${BASH_SOURCE[1]}"
    exo_setup_context "$calling_script"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        source "$EXO_UTIL/launch.msh"
        return
    else
        source "$EXO_UTIL/launch.bsh"
        return
    fi
}

# ── macOS install entry point ─────────────────────────────────────────────────
# Called as the last line of every per-game install.bsh.
function exo_install {
    local calling_script="${BASH_SOURCE[1]}"
    local calling_dir
    calling_dir="$(cd "$(dirname "$calling_script")" && pwd)"
    folder="$calling_dir"
    export folder
    cd "$EXO_DIR"
    eval source "./util/install.sh" && exit 0
}
