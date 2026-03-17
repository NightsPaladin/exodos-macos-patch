#!/usr/bin/env bash
# exception.sh — game-specific launch override.
# Sourced by launch.sh/launch.bsh/launch.msh; exo_lib.sh context already loaded.

clear

: dosbox
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    flatpak run com.retro_exo.wine ./eXoDOS/WarCraft/WarcraftMouseHelper.exe "./emulators/dosbox/ece4481/DOSBox.exe" -conf "./eXoDOS/"\!"dos/WarCraft/dosbox_linux.conf" -conf "./emulators/dosbox/options_linux.conf" -conf "${conf}" -noconsole -exit -nomenu
    rm stdout.txt
    rm stderr.txt
    [[ "$(ls -1 glide.* 2>/dev/null | wc -l)" -gt 0 ]] && rm glide.*
    [ -e ./eXoDOS/CWSDPMI.swp ] && rm ./eXoDOS/CWSDPMI.swp
elif [[ "$OSTYPE" == "darwin"* ]]; then
    "${EXO_EMULATOR_CMD[@]}" \
        -conf "$DOS_DIR/$gamedir/dosbox_linux.conf" \
        -conf "$EXO_DIR/emulators/dosbox/options_macos.conf" \
        -conf "$DOS_DIR/$gamedir/dosbox_macos.conf" \
        -nomenu -noconsole
    rm -f stdout.txt stderr.txt
    compgen -G 'glide.*' &>/dev/null && rm -f glide.*
    [[ -f "$DOSBASE/CWSDPMI.swp" ]] && rm -f "$DOSBASE/CWSDPMI.swp"
fi
goto end && [[ $0 != $BASH_SOURCE ]] && return
: end
[[ $0 != $BASH_SOURCE ]] && return
