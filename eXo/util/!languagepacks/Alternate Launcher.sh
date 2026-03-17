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

. "./util/${languagefolder}/texts_linux.txt"
sdl_windows_dpi_scaling=0
cnt=0
folderpath="$(cat ./util/alt_launch_linux.txt | head -n 1)"
[ ! -e ./eXoDOS/"${languagefolder}"/"${gamedir}"/ ] && goto none && [[ $0 != $BASH_SOURCE ]] && return

: launch
[ ! -e ./emulators/dosbox/alt_settings_linux.txt ] && goto next && [[ $0 != $BASH_SOURCE ]] && return
ppmode1=`grep "PPmode" ./emulators/dosbox/alt_settings_linux.txt | tail -1 | tr -d "\r"`
ppmode="${ppmode1#*:}"
crt1=`grep "CRT:" ./emulators/dosbox/alt_settings_linux.txt | tail -1 | tr -d "\r"`
crt="${crt1#*:}"
nsl1=`grep "nslmode:" ./emulators/dosbox/alt_settings_linux.txt | tail -1 | tr -d "\r"`
nsl="${nsl1#*:}"
shader1=`grep "glshader" ./emulators/dosbox/alt_settings_linux.txt | tail -1 | tr -d "\r"`
shader="${shader1#*/}"
shadert2="${shader1#*:}"
shadert="${shadert2%%/*}"
filter="${shader1#*:}"

dosbox="$(cat ./util/alt_dosbox_linux.txt | head -n 1)"
if [ "${crt}" == On ]
then
       if [ "${ppmode}" == On ]
       then
              conf="./emulators/dosbox/Staging_crt_PP_linux.conf"
              goto ps && [[ $0 != $BASH_SOURCE ]] && return
       fi
fi
if [ "${crt}" == On ]
then
       if [ "${ppmode}" == Off ]
       then
              conf="./emulators/dosbox/Staging_crt_linux.conf"
              goto ps && [[ $0 != $BASH_SOURCE ]] && return
       fi
fi
if [ "${nsl}" == On ]
then
       if [ "${ppmode}" == Off ]
       then
              conf="./emulators/dosbox/Staging_noline_linux.conf"
              goto ps && [[ $0 != $BASH_SOURCE ]] && return
       fi
fi
if [ "${nsl}" == On ]
then
       if [ "${ppmode}" == On ]
       then
              conf="./emulators/dosbox/Staging_noline_PP_linux.conf"
              goto ps && [[ $0 != $BASH_SOURCE ]] && return
       fi
fi
if [ "${crt}" == Off ]
then
       if [ "${ppmode}" == On ]
       then
              conf="./emulators/dosbox/Staging_PP_linux.conf"
              goto ps && [[ $0 != $BASH_SOURCE ]] && return
       fi
fi

: ps
[ "${crt}" == Off ] && shader=Off
[ "${nsl}" == On ] && shader=Off
clear
echo ""
echo "${altlauncherline0052}"
echo "Integer Scaling:          ${ppmode}"
# echo CRT:                      ${crt}
echo "No Scan Lines:            ${nsl}"
# if "${crt}"==Off goto blip
[ "${shader}" == glshader:crt-auto ] && goto blip2 && [[ $0 != $BASH_SOURCE ]] && return
echo "Shader:                   ${shader}"
: blip2
[ "${nsl}" == Off ] && echo "Shader Type:              ${shadert}"
: blip
echo ""
echo "${altlauncherline0001}"
echo ""
dynchoice "${altlauncherline0002}" "${altlauncherline0003}"

[ $errorlevel == '2' ] && goto next && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto preinstall && [[ $0 != $BASH_SOURCE ]] && return

: next
clear
echo ""
echo "${altlauncherline0004}"
echo "${altlauncherline0005}"
echo "${altlauncherline0006}"
echo "${altlauncherline0007}"
echo "${altlauncherline0008}"
echo ""
echo "${altlauncherline0009}"
echo "${altlauncherline0010}"
echo ""
echo "${altlauncherline0011}"
echo "${altlauncherline0012}"
echo ""
echo "${altlauncherline0013}"
echo ""
echo "${altlauncherline0014}"
echo ""
while true
do
    read -p "${altlauncherline0015} " choice
    case $choice in
        [1] ) errorlevel=1
                break;;
        [2] ) errorlevel=2
                break;;
        [3] ) errorlevel=3
                break;;
        [4] ) errorlevel=4
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '4' ] && goto quit && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '3' ] && goto addnslpp && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto crtmode && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto ppmode && [[ $0 != $BASH_SOURCE ]] && return

: ppmode
dosbox="$(cat ./util/alt_dosbox_linux.txt | head -n 1)"
filter=Sharp
conf=./emulators/dosbox/Staging_PP_linux.conf
echo "PPmode:On" > ./emulators/dosbox/alt_settings_linux.txt
echo "CRT:Off" >> ./emulators/dosbox/alt_settings_linux.txt
echo "nslmode:Off" >> ./emulators/dosbox/alt_settings_linux.txt
[ -e ./util/check.txt ] && goto install && [[ $0 != $BASH_SOURCE ]] && return
echo ""
echo "${altlauncherline0016}"
echo "${altlauncherline0017}"
echo "${altlauncherline0018}"
echo "${altlauncherline0019}"
echo ""
echo "${altlauncherline0020}"
echo "${altlauncherline0021}"
echo "${altlauncherline0022}"
echo "${altlauncherline0023}"
echo "${altlauncherline0024}"
echo "${altlauncherline0025}"
echo ""
echo "${altlauncherline0026}"
echo "${altlauncherline0027}"
echo "${altlauncherline0028}"
echo "${altlauncherline0029}"
echo "${altlauncherline0030}"
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"
echo "" >> ./util/check.txt
goto install && [[ $0 != $BASH_SOURCE ]] && return

: crtmode
dosbox="$(cat ./util/alt_dosbox_linux.txt | head -n 1)"
clear
echo ""
echo "${altlauncherline0031}"
echo ""
echo "${altlauncherline0032}"
echo "${altlauncherline0033}"
echo "${altlauncherline0034}"
echo "${altlauncherline0035}"
echo "${altlauncherline0036}"
echo "${altlauncherline0037}"
echo ""
while true
do
    read -p "${altlauncherline0038} " choice
    case $choice in
        [1] ) errorlevel=1
                break;;
        [2] ) errorlevel=2
                break;;
        [3] ) errorlevel=3
                break;;
        [4] ) errorlevel=4
                break;;
        [5] ) errorlevel=5
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '5' ] && goto quit && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '4' ] && goto scaler && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '3' ] && goto intshader && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto crtshader && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto acrtshader && [[ $0 != $BASH_SOURCE ]] && return

: acrtshader
filter=crt-auto
goto addpp && [[ $0 != $BASH_SOURCE ]] && return

: crtshader
cd "${folderpath}"resources/glshaders/crt2
clear
echo ""
echo "${altlauncherline0053}"
while read -d $'\0' a
do
    cnt=$(( "${cnt}"+1 ))
    declare select"${cnt}"="${a}"
    name="${a}"
    echo " ${cnt} ${altlauncherline0054} ${name::-5}"
done < <(find . -mindepth 1 -maxdepth 1 -printf "%P\n\0" | sort -z)
echo ""
/p crt="${altlauncherline0039}"
[ "${crt}" == 1 ] && filter=crt2/"${select1}"
[ "${crt}" == 2 ] && filter=crt2/"${select2}"
[ "${crt}" == 3 ] && filter=crt2/"${select3}"
[ "${crt}" == 4 ] && filter=crt2/"${select4}"
[ "${crt}" == 5 ] && filter=crt2/"${select5}"
[ "${crt}" == 6 ] && filter=crt2/"${select6}"
[ "${crt}" == 7 ] && filter=crt2/"${select7}"
[ "${crt}" == 8 ] && filter=crt2/"${select8}"
[ "${crt}" == 9 ] && filter=crt2/"${select9}"
[ "${crt}" == 10 ] && filter=crt2/"${select10}"
[ "${crt}" == 11 ] && filter=crt2/"${select11}"
[ "${crt}" == 12 ] && filter=crt2/"${select12}"
[ "${crt}" == 13 ] && filter=crt2/"${select13}"
[ "${crt}" == 14 ] && filter=crt2/"${select14}"
[ "${crt}" == 15 ] && filter=crt2/"${select15}"
[ "${crt}" == 16 ] && filter=crt2/"${select16}"
[ "${crt}" == 17 ] && filter=crt2/"${select17}"
[ "${crt}" == 18 ] && filter=crt2/"${select18}"
[ "${crt}" == 19 ] && filter=crt2/"${select19}"
[ "${crt}" == 20 ] && filter=crt2/"${select20}"
[ "${crt}" == 21 ] && filter=crt2/"${select21}"
[ "${crt}" == 22 ] && filter=crt2/"${select22}"
[ "${crt}" == 23 ] && filter=crt2/"${select23}"
[ "${crt}" == 24 ] && filter=crt2/"${select24}"
[ "${crt}" == 25 ] && filter=crt2/"${select25}"
[ "${crt}" == 26 ] && filter=crt2/"${select26}"
[ "${crt}" == 27 ] && filter=crt2/"${select27}"
[ "${crt}" == 28 ] && filter=crt2/"${select28}"
[ "${crt}" == 29 ] && filter=crt2/"${select29}"
[ "${crt}" == 30 ] && filter=crt2/"${select30}"
cd ../../../../../../
goto addpp && [[ $0 != $BASH_SOURCE ]] && return

: intshader
cd "${folderpath}"resources/glshaders/interpolation
clear
echo ""
echo "${altlauncherline0055}"
while read -d $'\0' a
do
    cnt=$(( "${cnt}"+1 ))
    declare select"${cnt}"="${a}"
    name="${a}"
    echo " ${cnt} ${altlauncherline0056} ${name::-5}"
done < <(find . -mindepth 1 -maxdepth 1 -printf "%P\n\0" | sort -z)
echo ""
/p int="${altlauncherline0040}"
[ "${int}" == 1 ] && filter=interpolation/"${select1}"
[ "${int}" == 2 ] && filter=interpolation/"${select2}"
[ "${int}" == 3 ] && filter=interpolation/"${select3}"
[ "${int}" == 4 ] && filter=interpolation/"${select4}"
[ "${int}" == 5 ] && filter=interpolation/"${select5}"
[ "${int}" == 6 ] && filter=interpolation/"${select6}"
[ "${int}" == 7 ] && filter=interpolation/"${select7}"
[ "${int}" == 8 ] && filter=interpolation/"${select8}"
[ "${int}" == 9 ] && filter=interpolation/"${select9}"
[ "${int}" == 10 ] && filter=interpolation/"${select10}"
cd ../../../../../../
goto addpp && [[ $0 != $BASH_SOURCE ]] && return

: scaler
cd "${folderpath}"resources/glshaders/scaler
clear
echo ""
echo "${altlauncherline0057}"
while read -d $'\0' a
do
    cnt=$(( "${cnt}"+1 ))
    declare select"${cnt}"="${a}"
    name="${a}"
    echo " ${cnt} ${altlauncherline0058} ${name::-5}"
done < <(find . -mindepth 1 -maxdepth 1 -printf "%P\n\0" | sort -z)
echo ""
/p sca="${altlauncherline0041}"
[ "${sca}" == 1 ] && filter=scaler/"${select1}"
[ "${sca}" == 2 ] && filter=scaler/"${select2}"
[ "${sca}" == 3 ] && filter=scaler/"${select3}"
[ "${sca}" == 4 ] && filter=scaler/"${select4}"
[ "${sca}" == 5 ] && filter=scaler/"${select5}"
[ "${sca}" == 6 ] && filter=scaler/"${select6}"
[ "${sca}" == 7 ] && filter=scaler/"${select7}"
[ "${sca}" == 8 ] && filter=scaler/"${select8}"
[ "${sca}" == 9 ] && filter=scaler/"${select9}"
[ "${sca}" == 10 ] && filter=scaler/"${select10}"
cd ../../../../../../
goto addpp && [[ $0 != $BASH_SOURCE ]] && return

: addpp
clear
echo ""
echo "${altlauncherline0042}"
echo ""
dynchoice "${altlauncherline0043}" "${altlauncherline0044}"

[ $errorlevel == '2' ] && goto crtnopp && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto crtpp && [[ $0 != $BASH_SOURCE ]] && return

: crtpp
echo "PPmode:On" > ./emulators/dosbox/alt_settings_linux.txt
echo "CRT:On" >> ./emulators/dosbox/alt_settings_linux.txt
echo "nslmode:Off" >> ./emulators/dosbox/alt_settings_linux.txt
conf=./emulators/dosbox/Staging_crt_PP_linux.conf
sed -i -e "s|glshader=|glshader=${filter}|g" ./emulators/dosbox/Staging_crt_PP_linux.conf
goto install && [[ $0 != $BASH_SOURCE ]] && return

: crtnopp
echo "PPmode:Off" > ./emulators/dosbox/alt_settings_linux.txt
echo "CRT:On" >> ./emulators/dosbox/alt_settings_linux.txt
echo "nslmode:Off" >> ./emulators/dosbox/alt_settings_linux.txt
conf=./emulators/dosbox/Staging_crt_linux.conf
sed -i -e "s|glshader=|glshader=${filter}|g" ./emulators/dosbox/Staging_crt_linux.conf
goto install && [[ $0 != $BASH_SOURCE ]] && return

: addnslpp
clear
echo ""
echo "${altlauncherline0045}"
echo ""
dynchoice "${altlauncherline0046}" "${altlauncherline0047}"

[ $errorlevel == '2' ] && goto nslmodenopp && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto nslmodepp && [[ $0 != $BASH_SOURCE ]] && return

: nslmodenopp
filter=None
echo "PPmode:Off" > ./emulators/dosbox/alt_settings_linux.txt
echo "CRT:Off" >> ./emulators/dosbox/alt_settings_linux.txt
echo "nslmode:On" >> ./emulators/dosbox/alt_settings_linux.txt
dosbox="$(cat ./util/alt_dosbox_linux.txt | head -n 1)"
conf=./emulators/dosbox/Staging_noline_linux.conf
goto install && [[ $0 != $BASH_SOURCE ]] && return

: nslmodepp
filter=None
echo "PPmode:On" > ./emulators/dosbox/alt_settings_linux.txt
echo "CRT:Off" >> ./emulators/dosbox/alt_settings_linux.txt
echo "nslmode:On" >> ./emulators/dosbox/alt_settings_linux.txt
dosbox="$(cat ./util/alt_dosbox_linux.txt | head -n 1)"
conf=./emulators/dosbox/Staging_noline_PP_linux.conf
goto install && [[ $0 != $BASH_SOURCE ]] && return

: preinstall
[ "${conf}" == "./emulators/dosbox/Staging_PP_linux.conf" ] && goto install && [[ $0 != $BASH_SOURCE ]] && return
[ "${conf}" == "./emulators/dosbox/Staging_noline_linux.conf" ] && goto install && [[ $0 != $BASH_SOURCE ]] && return
[ "${conf}" == "./emulators/dosbox/Staging_noline_PP_linux.conf" ] && goto install && [[ $0 != $BASH_SOURCE ]] && return
sed -i -e "s|glshader=|glshader=${filter}|g" ${conf}
goto postinstall && [[ $0 != $BASH_SOURCE ]] && return

: install
echo "glshader:${filter}" >> ./emulators/dosbox/alt_settings_linux.txt
: postinstall
eval "$(echo "${dosbox}" | sed -e "s/\\$/\\\\$/g")" -conf \"$(echo "${var}" | sed -e "s/\\$/\\\\$/g")/dosbox_linux.conf\" -conf \"./emulators/dosbox/options_linux.conf\" -conf \"$(echo "${conf}" | sed -e "s/\\$/\\\\$/g")\" -exit -nomenu -noconsole
sed -i -e "s|glshader=${filter}|glshader=|g" ./emulators/dosbox/Staging_crt_linux.conf
sed -i -e "s|glshader=${filter}|glshader=|g" ./emulators/dosbox/Staging_crt_PP_linux.conf
rm stdout.txt
rm stderr.txt
[[ "$(ls -1 glide.* 2>/dev/null | wc -l)" -gt 0 ]] && rm glide.*
[ -e ./eXoDOS/CWSDPMI.swp ] && rm ./eXoDOS/CWSDPMI.swp
goto end && [[ $0 != $BASH_SOURCE ]] && return

: none
clear
echo ""
echo "${altlauncherline0048}"
echo ""
echo ""
echo "${altlauncherline0049}"
echo ""
dynchoice "${altlauncherline0050}" "${altlauncherline0051}"

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
goto launch && [[ $0 != $BASH_SOURCE ]] && return
: no
goto end && [[ $0 != $BASH_SOURCE ]] && return

: end
[[ $0 != $BASH_SOURCE ]] && return
