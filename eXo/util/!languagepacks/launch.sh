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
    missingDependencies=no
    ! [[ `which brew` ]] && missingDependencies=yes
    ! [[ `which aria2c` ]] && missingDependencies=yes
    ! [[ `spctl --status | grep disabled` ]] && missingDependencies=yes
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

sdl_windows_dpi_scaling=0
[ -e ./util/AYES.SEL ] && sed -i -e "s|aspect=false|aspect=true|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/ANO.SEL ] && sed -i -e "s|aspect=true|aspect=false|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/FULL.SEL ] && sed -i -e "s|fullscreen=false|fullscreen=true|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/WIN.SEL ] && sed -i -e "s|fullscreen=true|fullscreen=false|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/SML.SEL ] && sed -i -e "s|windowresolution=1280x960|windowresolution=640x480|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/SML.SEL ] && sed -i -e "s|windowresolution=2560x1920|windowresolution=640x480|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/MED.SEL ] && sed -i -e "s|windowresolution=640x480|windowresolution=1280x960|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/MED.SEL ] && sed -i -e "s|windowresolution=2560x1920|windowresolution=1280x960|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/LRG.SEL ] && sed -i -e "s|windowresolution=640x480|windowresolution=2560x1920|g" ./emulators/dosbox/options_linux.conf
[ -e ./util/LRG.SEL ] && sed -i -e "s|windowresolution=1280x960|windowresolution=2560x1920|g" ./emulators/dosbox/options_linux.conf
. "./util/${languagefolder}/texts_linux.txt"
clear
[ ! -e ./eXoDOS/"${languagefolder}"/"${gamedir}"/ ] && goto none && [[ $0 != $BASH_SOURCE ]] && return

: launch
[ ! -e ./eXoDOS/"${languagefolder}"/"${gamedir}"/ ] && goto end && [[ $0 != $BASH_SOURCE ]] && return
dosindex=`grep "^${gamename}" ./util/${languagefolder}/dosbox_linux.txt | tail -1 | tr -d "\r"`
dosbox1="${dosindex#*:}"
dosbox="${dosbox1#*:}"
grep -q "${gamename}" "./util/${languagefolder}/multiplayer.txt" && multi=yes
[ "${multi}" = "" ] && goto start && [[ $0 != $BASH_SOURCE ]] && return

cd "./eXoDOS/${languagefolder}/${gamedir}/"
scriptDirStack["${#scriptDirStack[@]}"]="$scriptDir"
[ "${multi}" == "yes" ] && eval source ./../../../util/\!languagepacks/ip.bsh
scriptDir="${scriptDirStack["${#scriptDirStack[@]}"-1]}"
unset scriptDirStack["${#scriptDirStack[@]}"-1]
function goto
{
    shortcutName=$1
    newPosition=$(sed -n -e "/: $shortcutName$/{:a;n;p;ba};" "$scriptDir/$(basename -- "$BASH_SOURCE")" )
    eval "$newPosition"
    exit
}

: start
scriptDirStack["${#scriptDirStack[@]}"]="$scriptDir"
[ -e ./eXoDOS/\!dos/${languagefolder}/"${gamedir}"/exception.bsh ] && eval source "./eXoDOS/"\!"dos/$(echo "${languagefolder}" | sed -e "s/\\$/\\\\$/g")/$(echo "${gamedir}" | sed -e "s/\\$/\\\\$/g")/exception.bsh"
scriptDir="${scriptDirStack["${#scriptDirStack[@]}"-1]}"
unset scriptDirStack["${#scriptDirStack[@]}"-1]
function goto
{
    shortcutName=$1
    newPosition=$(sed -n -e "/: $shortcutName$/{:a;n;p;ba};" "$scriptDir/$(basename -- "$BASH_SOURCE")" )
    eval "$newPosition"
    exit
}
[ -e ./eXoDOS/\!dos/"${languagefolder}"/"${gamedir}"/exception.bsh ] && goto end && [[ $0 != $BASH_SOURCE ]] && return
clear
eval "$(echo "${dosbox}" | sed -e "s/\\$/\\\\$/g")" -conf \"$(echo "${var}" | sed -e "s/\\$/\\\\$/g")/dosbox_linux.conf\" -conf \"./emulators/dosbox/options_linux.conf\" -noconsole -exit -nomenu
rm stdout.txt
rm stderr.txt
[[ "$(ls -1 glide.* 2>/dev/null | wc -l)" -gt 0 ]] && rm glide.*
[ -e ./eXoDOS/CWSDPMI.swp ] && rm ./eXoDOS/CWSDPMI.swp
goto end && [[ $0 != $BASH_SOURCE ]] && return

: none
clear
echo ""
echo "${line0001}"
echo ""
echo ""
echo "${line0002}"
echo ""
dynchoice "${line0006}" "${line0007}"

[ $errorlevel == '2' ] && goto no && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto yes && [[ $0 != $BASH_SOURCE ]] && return
: yes
cd "${var}"
scriptDirStack["${#scriptDirStack[@]}"]="$scriptDir"
eval source install.bsh
scriptDir="${scriptDirStack["${#scriptDirStack[@]}"-1]}"
unset scriptDirStack["${#scriptDirStack[@]}"-1]
function goto
{
    shortcutName=$1
    newPosition=$(sed -n -e "/: $shortcutName$/{:a;n;p;ba};" "$scriptDir/$(basename -- "$BASH_SOURCE")" )
    eval "$newPosition"
    exit
}
cd ..
cd ..
clear
goto launch && [[ $0 != $BASH_SOURCE ]] && return
: no
goto end && [[ $0 != $BASH_SOURCE ]] && return

: end
[[ $0 != $BASH_SOURCE ]] && return
