#!/usr/bin/env bash
if [[ "$LD_PRELOAD" =~ "gameoverlayrenderer" ]]
then
    LD_PRELOAD=""
fi
[[ $0 == $BASH_SOURCE ]] && cd "$( dirname "$0")"
scriptDir="$(cd "$( dirname "$BASH_SOURCE")" && pwd)"
[ $# -gt 0 ] && parameterone="$1"
[ $# -gt 1 ] && parametertwo="$2"
[ $# -gt 2 ] && parameterthree="$3"
[ $# -gt 3 ] && parameterfour="$4"

# Load shared utilities: goto, dynchoice, _SED, bash-version guard, PATH
source "$scriptDir/../exo_lib.sh"

# Dependency checks
if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    depcheck=flatpak
    missingDependencies=no
    if [ $depcheck == "flatpak" ]
    then
        ! [[ `which flatpak` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.aria2c"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-074r3-1"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-ece-r4301"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-ece-r4358"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-ece-r4482"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-gridc-4-3-1"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-staging-082-0"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-staging-081-2"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-x-08220"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-x-20240701"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.gzdoom-4-11-3"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.scummvm-2-2-0"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.scummvm-2-3-0-git15811-gf97bfb7ce1"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.vlc"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.wine"` ]] && missingDependencies=yes
    elif [ $depcheck == "native" ]
    then
        ! [[ `which dosbox-074r3-1` ]] && missingDependencies=yes
        ! [[ `which dosbox-ece-r4301` ]] && missingDependencies=yes
        ! [[ `which dosbox-ece-r4358` ]] && missingDependencies=yes
        ! [[ `which dosbox-ece-r4482` ]] && missingDependencies=yes
        ! [[ `which dosbox-gridc-4-3-1` ]] && missingDependencies=yes
        ! [[ `which dosbox-staging-082-0` ]] && missingDependencies=yes
        ! [[ `which dosbox-staging-081-2` ]] && missingDependencies=yes
        ! [[ `which dosbox-x-08220` ]] && missingDependencies=yes
        ! [[ `which dosbox-x-20240701` ]] && missingDependencies=yes
        ! [[ `which gzdoom-4-11-3` ]] && missingDependencies=yes
        ! [[ `which scummvm-2-2-0` ]] && missingDependencies=yes
        ! [[ `which scummvm-2-3-0-git15811-gf97bfb7ce1` ]] && missingDependencies=yes
        ! [[ `which aria2c` ]] && missingDependencies=yes
        ! [[ `which vlc` ]] && missingDependencies=yes
        ! [[ `which wine` ]] && missingDependencies=yes
    else
        missingDependencies=yes
    fi
    ! [[ `which curl` ]] && missingDependencies=yes
    ! [[ `which python3` ]] && missingDependencies=yes
    ! [[ `which sed` ]] && missingDependencies=yes
    ! [[ `which unzip` ]] && missingDependencies=yes
    ! [[ `which wget` ]] && missingDependencies=yes
elif [[ "$OSTYPE" == "darwin"* ]]
then
    depcheck=flatpak
    missingDependencies=no
    if [ $depcheck == "flatpak" ]
    then
        ! [[ `which flatpak` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.aria2c"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-074r3-1"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-ece-r4301"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-ece-r4358"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-ece-r4482"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-gridc-4-3-1"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-staging-082-0"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-staging-081-2"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-x-08220"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.dosbox-x-20240701"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.gzdoom-4-11-3"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.scummvm-2-2-0"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.scummvm-2-3-0-git15811-gf97bfb7ce1"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.vlc"` ]] && missingDependencies=yes
        ! [[ `flatpak list 2>/dev/null | grep "retro_exo\.wine"` ]] && missingDependencies=yes
    elif [ $depcheck == "native" ]
    then
        ! [[ `which dosbox-074r3-1` ]] && missingDependencies=yes
        ! [[ `which dosbox-ece-r4301` ]] && missingDependencies=yes
        ! [[ `which dosbox-ece-r4358` ]] && missingDependencies=yes
        ! [[ `which dosbox-ece-r4482` ]] && missingDependencies=yes
        ! [[ `which dosbox-gridc-4-3-1` ]] && missingDependencies=yes
        ! [[ `which dosbox-staging-082-0` ]] && missingDependencies=yes
        ! [[ `which dosbox-staging-081-2` ]] && missingDependencies=yes
        ! [[ `which dosbox-x-08220` ]] && missingDependencies=yes
        ! [[ `which dosbox-x-20240701` ]] && missingDependencies=yes
        ! [[ `which gzdoom-4-11-3` ]] && missingDependencies=yes
        ! [[ `which scummvm-2-2-0` ]] && missingDependencies=yes
        ! [[ `which scummvm-2-3-0-git15811-gf97bfb7ce1` ]] && missingDependencies=yes
        ! [[ `which aria2c` ]] && missingDependencies=yes
        ! [[ `which vlc` ]] && missingDependencies=yes
        ! [[ `which wine` ]] && missingDependencies=yes
    else
        missingDependencies=yes
    fi
    ! [[ `which curl` ]] && missingDependencies=yes
    ! [[ `which python3` ]] && missingDependencies=yes
    ! [[ `which sed` ]] && missingDependencies=yes
    ! [[ `which unzip` ]] && missingDependencies=yes
    ! [[ `which wget` ]] && missingDependencies=yes
fi

if [ $missingDependencies == "yes" ]
then
    printf "\n\e[1;31;47mOne or more dependencies are missing.\e[0m\n\n"
    printf "Please run the \e[1;33;40minstall_dependencies.command\e[0m script.\n"
    printf "Then, follow the instructions to install the required dependencies.\n"
    read -s -n 1 -p "Press any key to abort."
    printf "\n\n"
    exit 0
fi

flatpak run com.retro_exo.wine SumatraPDF.exe -fullscreen -page ${parametertwo} "../../Magazines/${parameterone}/${parameterthree}/${parameterfour}"
[[ $0 != $BASH_SOURCE ]] && return
