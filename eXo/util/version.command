#!/usr/bin/env bash
if [[ "$LD_PRELOAD" =~ "gameoverlayrenderer" ]]
then
    LD_PRELOAD=""
fi
cd "$( dirname "$BASH_SOURCE")"

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    if [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "konsole" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "gnome-terminal-" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "xfce4-terminal" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "kgx" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "xterm" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "Eterm" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "x-terminal-emul" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "mate-terminal" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "terminator" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "urxvt" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "rxvt" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "termit" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "terminology" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "tilix" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "kitty" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `ps -o sid= -p "$$" | xargs ps -o ppid= -p | xargs ps -o comm= -p` = "aterm" ]
    then
        source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
        exit 0
    elif [ `which konsole` ]
    then
        konsole -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which gnome-terminal` ]
    then
        gnome-terminal -- /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which xfce4-terminal` ]
    then
        xfce4-terminal -x /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which kgx` ]
    then
        kgx -e "/usr/bin/env bash \"$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")\" $@" &
        exit 0
    elif [ `which xterm` ]
    then
        xterm -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which uxterm` ]
    then
        uxterm -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which eterm` ]
    then
        Eterm -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which x-terminal-emulator` ]
    then
        x-terminal-emulator -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which mate-terminal` ]
    then
        eval mate-terminal -e \"/usr/bin/env bash \\\"$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")\\\" $@\" "$@" &
        exit 0
    elif [ `which terminator` ]
    then
        terminator -x /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which urxvt` ]
    then
        urxvt -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which rxvt` ]
    then
        rxvt -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which termit` ]
    then
        termit -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which lxterm` ]
    then
        lxterm -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which terminology` ]
    then
        terminology -e "/usr/bin/env bash \"$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")\" $@" &
        exit 0
    elif [ `which tilix` ]
    then
        tilix -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which kitty` ]
    then
        kitty -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    elif [ `which aterm` ]
    then
        aterm -e /usr/bin/env bash "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")" "$@" &
        exit 0
    else
        exit ERRCODE "Weird system achievement unlocked: None of the 18 supported terminal emulators are installed."
    fi
elif [[ "$OSTYPE" == "darwin"* ]]
then
    source "$PWD/$(basename -- "${BASH_SOURCE%.command}.sh")"
    exit 0
else
    exit ERRCODE "Unsupported OS"
fi
