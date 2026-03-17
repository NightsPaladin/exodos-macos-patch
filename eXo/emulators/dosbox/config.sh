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
source "$scriptDir/../../util/exo_lib.sh"

# Dependency checks
if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    depcheck=flatpak
    missingDependencies=no
    if [ $depcheck == "flatpak" ]
    then
        ! [[ `which flatpak` ]] && missingDependencies=yes
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

clear
echo ""
echo "Would you like [F]ullscreen or [W]indowed mode to be the default setting?"
echo ""
while true
do
    read -p "Please choose (F/W): " choice
    case $choice in
        [Ff]* ) errorlevel=1
                break;;
        [Ww]* ) errorlevel=2
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '2' ] && goto win && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto full && [[ $0 != $BASH_SOURCE ]] && return

: full
clear
$_SED -i -e "s|fullscreen=false|fullscreen=true|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/WIN.SEL ] && rm ./util/WIN.SEL
echo "" >  "./util/FULL.SEL"
goto res && [[ $0 != $BASH_SOURCE ]] && return

: win
clear
$_SED -i -e "s|fullscreen=true|fullscreen=false|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/FULL.SEL ] && rm ./util/FULL.SEL
echo "" >  "./util/WIN.SEL"
goto res && [[ $0 != $BASH_SOURCE ]] && return

: res
clear
echo ""
echo "What is your primary desktop resolution?"
echo "[L]arge (4k)"
echo "[M]edium (1080)"
echo "[S]mall (less than 1080)"
echo ""
echo "Note: This will be used to calculate the window size in windowed mode."
echo ""
while true
do
    read -p "Please choose (L/M/S): " choice
    case $choice in
        [Ll]* ) errorlevel=1
                break;;
        [Mm]* ) errorlevel=2
                break;;
        [Ss]* ) errorlevel=3
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '3' ] && goto small && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto medium && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto large && [[ $0 != $BASH_SOURCE ]] && return

: large
clear
$_SED -i -e "s|windowresolution=640x480|windowresolution=2560x1920|g" ./emulators/dosbox/options_linux.conf
$_SED -i -e "s|windowresolution=1280x960|windowresolution=2560x1920|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/MED.SEL ] && rm ./util/MED.SEL
[ -e ./util/SML.SEL ] && rm ./util/SML.SEL
echo "" >  "./util/LRG.SEL"
goto ratio && [[ $0 != $BASH_SOURCE ]] && return

: medium
clear
$_SED -i -e "s|windowresolution=640x480|windowresolution=1280x960|g" ./emulators/dosbox/options_linux.conf
$_SED -i -e "s|windowresolution=2560x1920|windowresolution=1280x960|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/LRG.SEL ] && rm ./util/LRG.SEL
[ -e ./util/SML.SEL ] && rm ./util/SML.SEL
echo "" >  "./util/MED.SEL"
goto ratio && [[ $0 != $BASH_SOURCE ]] && return

: small
clear
$_SED -i -e "s|windowresolution=1280x960|windowresolution=640x480|g" ./emulators/dosbox/options_linux.conf
$_SED -i -e "s|windowresolution=2560x1920|windowresolution=640x480|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/MED.SEL ] && rm ./util/MED.SEL
[ -e ./util/LRG.SEL ] && rm ./util/LRG.SEL
echo "" >  "./util/SML.SEL"
goto ratio && [[ $0 != $BASH_SOURCE ]] && return

: ratio
clear
echo ""
echo "Would you like to enable Aspect Correction for all games?"
echo ""
echo "Choosing Yes will attempt to preserve the game's original format. In fullscreen"
echo "mode this will introduce black bars on the sides."
echo ""
echo "Choosing No will stretch the image to fit your monitor."
echo ""
echo "Choosing 'Yes' is useful for widescreen monitors which cause stretching or distortion."
echo ""
while true
do
    read -p "[Y]es or [N]o " choice
    case $choice in
        [Yy]* ) errorlevel=1
                break;;
        [Nn]* ) errorlevel=2
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '2' ] && goto aspectn && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto aspecty && [[ $0 != $BASH_SOURCE ]] && return

: aspecty
clear
$_SED -i -e "s|aspect=false|aspect=true|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/ANO.SEL ] && rm ./util/ANO.SEL
echo "" >  "./util/AYES.SEL"
goto end && [[ $0 != $BASH_SOURCE ]] && return

: aspectn
clear
$_SED -i -e "s|aspect=true|aspect=false|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/AYES.SEL ] && rm ./util/AYES.SEL
echo "" >  "./util/ANO.SEL"
goto end && [[ $0 != $BASH_SOURCE ]] && return

: end
[[ $0 != $BASH_SOURCE ]] && return
