#!/usr/bin/env bash
# launch_helper.sh — Cross-platform GUI bridge for eXoDOS.
# Usage: launch_helper.sh <gamedir> <gamename>
#
# Sets context vars from CLI args then sources the platform-appropriate launcher:
#   macOS: launch.msh  (which also handles the macOS->Linux delegation internally)
#   Linux: launch.bsh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/exo_lib.sh"

gamedir="$1"
gamename="$2"
indexname="${gamename::-7}"
var="$DOS_DIR/$gamedir"
export gamedir gamename indexname var

if [[ "$OSTYPE" == "darwin"* ]]; then
    source "$EXO_UTIL/launch.msh"
else
    source "$EXO_UTIL/launch.bsh"
fi
