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
source "$scriptDir/exo_lib.sh"

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

cd "${folder}"
mediafiles=false
conf="${PWD}"
restore=NO
for i in .
do
    gamedir="${PWD##*/}"
done
for f in *\).bsh
do
    gamename2="${f}"
done
gamename="${gamename2::-4}"
indexname="${gamename::-7}"
cd ..
cd ..
cd ..

[ "${lang}" == "" ] && lang=false
[ "${lang_cnt}" == "" ] && lang_cnt=0
[ "${lang_cnt}" == 1 ] && goto skip_selection && [[ $0 != $BASH_SOURCE ]] && return
lang_cnt=0

[[ "$(ls -1 ./eXoDOS/\!dos/\!Chinese/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && lang_cnt=$(( "${lang_cnt}"+1 ))
[ -e ./eXoDOS/"${gamename}".zip ] && lang_cnt=$(( "${lang_cnt}"+1 ))
[[ "$(ls -1 ./eXoDOS/\!dos/\!French/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && lang_cnt=$(( "${lang_cnt}"+1 ))
[[ "$(ls -1 ./eXoDOS/\!dos/\!German/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && lang_cnt=$(( "${lang_cnt}"+1 ))
[[ "$(ls -1 ./eXoDOS/\!dos/\!Italian/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && lang_cnt=$(( "${lang_cnt}"+1 ))
[[ "$(ls -1 ./eXoDOS/\!dos/\!Korean/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && lang_cnt=$(( "${lang_cnt}"+1 ))
[[ "$(ls -1 ./eXoDOS/\!dos/\!Polish/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && lang_cnt=$(( "${lang_cnt}"+1 ))
[[ "$(ls -1 ./eXoDOS/\!dos/\!Russian/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && lang_cnt=$(( "${lang_cnt}"+1 ))
[[ "$(ls -1 ./eXoDOS/\!dos/\!Spanish/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && lang_cnt=$(( "${lang_cnt}"+1 ))

[ "${lang_cnt}" == 0 ] && goto english && [[ $0 != $BASH_SOURCE ]] && return
[ "${lang_cnt}" == 1 ] && goto skip_selection && [[ $0 != $BASH_SOURCE ]] && return
# if NOT "${lang}" == false goto skip_selection

clear
echo ""
echo "Language Selection Menu"
echo ""
[[ "$(ls -1 ./eXoDOS/\!dos/\!Chinese/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && echo "Press C to install or configure the Chinese version"
[ -e ./eXoDOS/"${gamename}".zip ] && echo "Press E to install or configure the English version"
[[ "$(ls -1 ./eXoDOS/\!dos/\!French/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && echo "Press F to install or configure the French version"
[[ "$(ls -1 ./eXoDOS/\!dos/\!German/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && echo "Press G to install or configure the German version"
[[ "$(ls -1 ./eXoDOS/\!dos/\!Italian/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && echo "Press I to install or configure the Italian version"
[[ "$(ls -1 ./eXoDOS/\!dos/\!Korean/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && echo "Press K to install or configure the Korean version"
[[ "$(ls -1 ./eXoDOS/\!dos/\!Polish/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && echo "Press P to install or configure the Polish version"
[[ "$(ls -1 ./eXoDOS/\!dos/\!Russian/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && echo "Press R to install or configure the Russian version"
[[ "$(ls -1 ./eXoDOS/\!dos/\!Spanish/"${gamedir}"/*\).bsh 2>/dev/null | wc -l)" -gt 0 ]] && echo "Press S to install or configure the Spanish version"
echo "Press X to Quit"
echo ""
while true
do
    read -p "Please Choose: " choice
    case $choice in
        [Cc]* ) errorlevel=1
                break;;
        [Ee]* ) errorlevel=2
                break;;
        [Ff]* ) errorlevel=3
                break;;
        [Gg]* ) errorlevel=4
                break;;
        [Ii]* ) errorlevel=5
                break;;
        [Kk]* ) errorlevel=6
                break;;
        [Pp]* ) errorlevel=7
                break;;
        [Rr]* ) errorlevel=8
                break;;
        [Ss]* ) errorlevel=9
                break;;
        [Xx]* ) errorlevel=10
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '1' ] && lang=\!chinese
[ $errorlevel == '2' ] && lang=\!english
[ $errorlevel == '3' ] && lang=\!french
[ $errorlevel == '4' ] && lang=\!german
[ $errorlevel == '5' ] && lang=\!italian
[ $errorlevel == '6' ] && lang=\!korean
[ $errorlevel == '7' ] && lang=\!polish
[ $errorlevel == '8' ] && lang=\!russian
[ $errorlevel == '9' ] && lang=\!spanish
[ $errorlevel == '10' ] && goto exit && [[ $0 != $BASH_SOURCE ]] && return

: skip_selection
[ "${lang}" == \!english ] && goto english && [[ $0 != $BASH_SOURCE ]] && return
cd "./eXoDOS/"\!"dos/${lang}/${gamedir}/"
eval source install.bsh && exit 0
clear

: english
for g in ./eXoDOS/"${gamename}".zip
do
    [ -e "$g" ] && size=`stat -c%s "$g"` || size="0"
done
[ "${size}" == "0" ] && rm ./eXoDOS/"${gamename}".zip
[ -e eXoDOS/"${gamename}".zip ] && goto next && [[ $0 != $BASH_SOURCE ]] && return

clear
gigabyte=false
totalsizemb=0
fullindex=`grep ":${gamename}" ./util/aria/index.txt | tail -1 | tr -d "\r"`
fullindex2=`grep ":./GameData/eXoDOS/${gamename}" ./util/aria/index.txt | tail -1 | tr -d "\r"`
filesize2="${fullindex2#*:}"
filesizex="${filesize2#*:}"
filesize1="${fullindex#*:}"
filesize="${filesize1#*:}"
removeindex="${fullindex#*:}"
result="$(printf '%s\n' "${fullindex//$removeindex}")"
index="${result::-1}"

[ "${fullindex2}" != "" ] && goto cont && [[ $0 != $BASH_SOURCE ]] && return
combinedsize="${filesize}"
filesizex=0Kib
goto dl && [[ $0 != $BASH_SOURCE ]] && return

: cont
mediafiles=true
removeindex2="${fullindex2#*:}"
result2="$(printf '%s\n' "${fullindex2//$removeindex2}")"
index="${result::-1}"
index2="${result2::-1}"
gamesize2="${filesize#* }"
contentsize2="${filesizex#* }"

# -=remove the parenthesis=-
gamesize3="${gamesize2:1:-1}"
contentsize3="${contentsize2:1:-1}"

# -=remove the comma=-
gamesize4="${gamesize3//,}"
contentsize4="${contentsize3//,}"

# -=Preliminary unit check. If more than 1 GB, special actions needed=-
unit=Gb
[ "${gamesize4}" -lt 1000000000 ] && unit=Mb
[ "${gamesize4}" -lt 1000000 ] && unit=Kb
[ "${gamesize4}" -lt 1000 ] && unit=b
[ "${unit}" == Gb ] && gigabyte=true

# -=Remove the one digit if it is over 1Gb due to integer limitations in batch=-
[ "${gigabyte}" == true ] && gamesize4="${gamesize4::-1}"
[ "${gigabyte}" == true ] && contentsize4="${contentsize4::-1}"

# -=Add content size to game size to determine final download size=-
totalsize=$(( "${gamesize4}"+"${contentsize4}" ))

# -=Add one's place back if it is over a Gb, as we removed it earlier=-
[ "${gigabyte}" == true ] && totalsize="${totalsize}"0

# -=Determine the combined unit=-
unit=Gb
[ "${totalsize}" -lt 1000000000 ] && unit=Mb
[ "${totalsize}" -lt 1000000 ] && unit=Kb
[ "${totalsize}" -lt 1000 ] && unit=b

# -=This section populates the Kb, Mb, and Gb variables, to build the final on the download page=-
totalsizekb="${totalsize::-3}"
[ "${totalsizekb}" == "" ] && totalsizekb="${totalsize}"

[ "${gigabyte}" == false ] && totalsizemb=$(( "${totalsize}"/1000000 ))
[ "${gigabyte}" == true ] && totalsizemb="${totalsize::-6}"
[ "${totalsizemb}" == "" ] && totalsizemb="${totalsize}"

[ "${gigabyte}" == false ] && totalsizegb=$(( "${totalsize}"/1000000000 ))
[ "${gigabyte}" == true ] && totalsizegb="${totalsize::-9}"
[ "${totalsizegb}" == "" ] && totalsizegb="${totalsize}"

# -=Based on Unit type, create the final value=-
[ "${unit}" == Gb ] && combinedsize="${totalsizegb}"."${totalsizemb:1:-1} ${unit}"
[ "${unit}" == Mb ] && combinedsize="${totalsizemb}"."${totalsizekb:3:-1} ${unit}"
[ "${unit}" == Kb ] && combinedsize="${totalsizekb} ${unit}"

# -=Check section, to verify values during testing=-
# echo filesize=${filesize}
# echo game size=${gamesize4}
# echo content size=${contentsize4}
# echo total size=${totalsize}
# echo total kb=${totalsizekb}
# echo total mb=${totalsizemb}
# echo index1 = ${index}
# echo index2 = ${index2}
# echo filesizex = ${filesizex}
# echo combined size = ${combinedsize}
# echo unit = ${unit}
# echo gigabyte = ${gigabyte}
# pause

: dl
clear
echo ""
echo "It appears you have not downloaded this game yet."
echo ""
echo "${gamename}'s download size is ${filesize}"
[ "${mediafiles}" == false ] && echo "There are no media files for this game."
[ "${mediafiles}" == true ] && echo "The media files for this game are ${filesizex}"
[ "${mediafiles}" == true ] && echo ""
[ "${mediafiles}" == true ] && echo "Total download will be ${combinedsize}"
echo ""
echo "Would you like to download it?"
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

[ $errorlevel == '2' ] && goto end && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto download && [[ $0 != $BASH_SOURCE ]] && return

: download
[[ "$(ps -e | grep aria2c | wc -l)" -gt 0 ]] && errorlevel="0 || errorlevel=1"
[ "${errorlevel}" == "0" ] && goto inprogress && [[ $0 != $BASH_SOURCE ]] && return

[ -e DOWNLOAD ] && rm -rf DOWNLOAD
mkdir DOWNLOAD
mkdir ./DOWNLOAD/GAMEDATA/
cp ./util/aria/eXoDOS.torrent ./DOWNLOAD/
cp ./util/aria/aria2c.exe ./DOWNLOAD/
cd DOWNLOAD
clear
flatpak run com.retro_exo.aria2c --select-file=${index} --index-out=${index}="${gamename}.zip" --file-allocation=none --allow-overwrite=true --seed-time=0 eXoDOS.torrent
flatpak run com.retro_exo.aria2c --select-file=${index2} --index-out=${index2}="./GAMEDATA/${gamename}.zip" --file-allocation=none --allow-overwrite=true --seed-time=0 eXoDOS.torrent
rm aria2c.exe
rm *.aria2
rm *.torrent
cd ..
mv "./DOWNLOAD/${gamename}.zip" "./eXoDOS/${gamename}.zip"
mv "./DOWNLOAD/GAMEDATA/${gamename}.zip" "../Content/GameData/eXoDOS/${gamename}.zip"
cd ..
unzip -o ./Content/GameData/eXoDOS/"${gamename}".zip -d ./
cd eXo
rm -rf DOWNLOAD
cd eXoDOS
for g in "${gamename}".zip
do
    [ -e "$g" ] && size=`stat -c%s "$g"` || size="0"
done
[ "${size}" == "0" ] && rm "${gamename}".zip
clear
echo ""
[ -e "${gamename}".zip ] && echo "Game Downloaded Successfully"
[ ! -e "${gamename}".zip ] && echo "There was an error downloading the game. Exiting..."
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"

cd ..
: next
[ -e ./eXoDOS/"${gamedir}"/ ] && goto dele && [[ $0 != $BASH_SOURCE ]] && return
: unzip
[ ! -e eXoDOS/"${gamename}".zip ] && goto exit && [[ $0 != $BASH_SOURCE ]] && return

[ ! -e ./eXoDOS/\!save/"${gamename}".zip ] && goto unzip2 && [[ $0 != $BASH_SOURCE ]] && return
clear
echo ""
echo "You have backed up save data for this game. Would you like to restore it?"
echo ""
while true
do
    read -p "[Y]es or [N]o, or [D]elete your Save " choice
    case $choice in
        [Yy]* ) errorlevel=1
                break;;
        [Nn]* ) errorlevel=2
                break;;
        [Dd]* ) errorlevel=3
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '3' ] && goto remove && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto unzip2 && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto restore && [[ $0 != $BASH_SOURCE ]] && return

: remove
rm ./eXoDOS/\!save/"${gamename}".zip
goto unzip2 && [[ $0 != $BASH_SOURCE ]] && return

: restore
restore=Y

: unzip2
unzip -o ./eXoDOS/"${gamename}".zip -d ./eXoDOS/
[ "${restore}" == Y ] && unzip -o ./eXoDOS/\!save/"${gamename}".zip -d ./eXoDOS/
runupdate=N
[ -e ./Update/\!dos/"${gamename}".zip ] && runupdate=Y
[ -e ./Update/\!dos/linux/release/"${gamename}".zip ] && runupdate=Y
[ -e ./Update/\!dos/linux/"${gamename}".zip ] && runupdate=Y
[ "${runupdate}" == N ] && goto config && [[ $0 != $BASH_SOURCE ]] && return

clear
echo ""
echo "An update for this game has been found. It will now be applied."
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"
[ -e ./Update/\!dos/"${gamename}".zip ] && unzip -o ./Update/\!dos/"${gamename}".zip -d ./eXoDOS/
[ -e ./Update/\!dos/linux/release/"${gamename}".zip ] && unzip -o ./Update/\!dos/linux/release/"${gamename}".zip -d ./eXoDOS/
[ -e ./Update/\!dos/linux/"${gamename}".zip ] && unzip -o ./Update/\!dos/linux/"${gamename}".zip -d ./eXoDOS/
goto config && [[ $0 != $BASH_SOURCE ]] && return

: dele
clear
echo ""
echo "Would you like to"
echo "[C]onfigure settings"
echo "[U]ninstall the game"
echo ""
while true
do
    read -p "Please Choose: [C,U] " choice
    case $choice in
        [Cc]* ) errorlevel=1
                break;;
        [Uu]* ) errorlevel=2
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '2' ] && goto erase && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto config && [[ $0 != $BASH_SOURCE ]] && return

: config
[ ! -e ./eXoDOS/"${gamedir}"/ ] && goto exit && [[ $0 != $BASH_SOURCE ]] && return
clear
echo ""
echo "Your current global config settings are:"
echo ""
[ -e ./util/WIN.SEL ] && echo "Windowed mode"
[ -e ./util/FULL.SEL ] && echo "Fullscreen mode"
[ -e ./util/SML.SEL ] && echo "Small desktop window resolution (less than 1080)"
[ -e ./util/MED.SEL ] && echo "Medium desktop window resolution (1080)"
[ -e ./util/LRG.SEL ] && echo "Large desktop window resolution (4k)"
[ -e ./util/ANO.SEL ] && echo "Aspect correction off"
[ -e ./util/AYES.SEL ] && echo "Aspect correction on"
echo ""
echo "Would you like to change any of these?"
echo ""
echo "NOTE: Desktop resolution is only used when in windowed mode. Fullscreen will"
echo "auto scale to your full desktop resolution."
echo ""
while true
do
    read -p "[Y]es or [N]o, or [?] for more information " choice
    case $choice in
        [Yy]* ) errorlevel=1
                break;;
        [Nn]* ) errorlevel=2
                break;;
        [?] ) errorlevel=3
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '3' ] && goto whatglob && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto scaler1 && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto aspect && [[ $0 != $BASH_SOURCE ]] && return

: whatglob
clear
echo ""
echo "These are Global Settings, in that they are applied to all games in the pack."
echo "If you have merged multiple eXo projects together, then these options will be"
echo "applied to all merged projects."
echo ""
echo "Fullscreen and Windowed are self-explanatory, however if you have chosen Windowed"
echo "then selecting the proper desktop resolution is important. Currently the three"
echo "\"buckets\" are resolutions lower than 1080, 1080-4k, and 4k or above. In the event"
echo "you feel your window size is too large or too small, simply re-run the configuration"
echo "and try the next size up or down."
echo ""
echo "Aspect ratio on attempts to preserve the game's original height to width ratio."
echo "Generally, DOS era monitors were 4:3 (W:H). Modern monitors are typically widescreen,"
echo "such as 16:9. If aspect ratio is off, a 4:3 game may be stretched out on the width"
echo "axis. Circles turn into ovals and characters become short & wide. The recommended"
echo "settings is \"ON\". A handful of games do not work properly with aspect ratio enabled."
echo "These have been setup to bypass the global option and always run with the setting"
echo "disabled."
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"
goto config && [[ $0 != $BASH_SOURCE ]] && return

: aspect
scriptDirStack["${#scriptDirStack[@]}"]="$scriptDir"
eval source ./emulators/dosbox/config.bsh
scriptDir="${scriptDirStack["${#scriptDirStack[@]}"-1]}"
unset scriptDirStack["${#scriptDirStack[@]}"-1]
function goto
{
    shortcutName=$1
    newPosition=$(sed -n -e "/: $shortcutName$/{:a;n;p;ba};" "$scriptDir/$(basename -- "$BASH_SOURCE")" )
    eval "$newPosition"
    exit
}
goto scaler1 && [[ $0 != $BASH_SOURCE ]] && return

: scaler1
clear
echo ""
echo "Would you like to change your graphics filter?"
echo ""
echo "Note: This only affects this game"
echo ""
while true
do
    read -p "[Y]es or [N]o, or [?] for more information " choice
    case $choice in
        [Yy]* ) errorlevel=1
                break;;
        [Nn]* ) errorlevel=2
                break;;
        [?] ) errorlevel=3
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '3' ] && goto whatsy && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto end && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto sy && [[ $0 != $BASH_SOURCE ]] && return

: whatsy
clear
echo ""
echo "This option is on a per game basis, it does not change globally."
echo ""
echo "Within DOSBox, the filter/scaler is a post-processed affect that either assists"
echo "in enhancing a low resolution image or adding a stylized effect."
echo ""
echo "DOS games generally had native resolutions between 320x200 to 640x480 (with a few"
echo "of the later games able to go even higher). On today's resolutions, this requires"
echo "some scaling in order to blow these screens up to a suitable size."
echo ""
echo "eXoDOS has the following scalers setup for easy access:"
echo "None         - With no scaler, you get a direct image that has no been modified"
echo "Normal2x/3x  - Uses nearest-neighbor to determine how to add pixels."
echo "HQ2x/3x      - An algorithm that interpolates pixels, and in turn tends to smooth out edges"
echo "2xsai        - This algorithm heavily smooths pixels out, to the point they may appear blurry"
echo "super2xsai   - So much smoothing that it almost begins to appear cell shaded"
echo "advmame2x/3x - Also known as EPX, this is a scaler that dates back to 1992."
echo "tv2          - adds scanlines to mimic a CRT"
echo ""
echo "Explanation of 2x/3x"
echo "2x - Expands a single pixel into a 2x2 block"
echo "3x - Expands a single pixel into a 3x3 block"
echo "Some scalers go up to 4x. However the higher this number gets, the bigger chance you have"
echo "of distortion and unexpected results."
echo ""
echo "Another option is to use the \"Pixel Perfect & Shader Options\" file, which can be found by right"
echo "clicking a game in LaunchBox and going to additional applications. Within this file are options"
echo "for Pixel Perfect, Curved CRT, and No Scan Lines (useful for FMV that has black lines)"
echo ""
echo "The eXoDOS manual (PDF) has a sample comparison of all of these scalers on the same image."
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"
goto scaler1 && [[ $0 != $BASH_SOURCE ]] && return

: sy
clear
echo ""
echo "Press 1 for no scaler"
echo "Press 2 for normal3x"
echo "Press 3 for hq2x"
echo "Press 4 for hq3x"
echo "Press 5 for 2xsai"
echo "Press 6 for super2xsai"
echo "press 7 for advmame2x"
echo "press 8 for advmame3x"
echo "press 9 for tv2x"
echo "Press 0 for normal2x"
echo ""
while true
do
    read -p "Please choose (0-9): " choice
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
        [6] ) errorlevel=6
                break;;
        [7] ) errorlevel=7
                break;;
        [8] ) errorlevel=8
                break;;
        [9] ) errorlevel=9
                break;;
        [0] ) errorlevel=10
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '10' ] && goto normal2x && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '9' ] && goto scaltv2x && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '8' ] && goto scalam3x && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '7' ] && goto scalam2x && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '6' ] && goto scals2xs && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '5' ] && goto scal2xs && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '4' ] && goto scalhq3x && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '3' ] && goto scalhq2x && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto scaln3x && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto scalno && [[ $0 != $BASH_SOURCE ]] && return

: scalno
sc=none
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: scaln3x
sc=normal3x
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: scalhq2x
sc=hq2x
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: scalhq3x
sc=hq3x
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: scal2xs
sc=2xsai
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: scals2xs
sc=super2xsai
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: scalam2x
sc=advmame2x
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: scalam3x
sc=advmame3x
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: scaltv2x
sc=tv2x
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: normal2x
sc=normal2x
goto scaler && [[ $0 != $BASH_SOURCE ]] && return

: scaler
cd "${conf}"
for z in *_linux.conf
do
    cd ..
    cd ..
    cd ..
    sed -i -e "s|scaler=none|scaler=${sc}|g" "${conf}/${z}"
    sed -i -e "s|scaler=normal3x|scaler=${sc}|g" "${conf}/${z}"
    sed -i -e "s|scaler=hq2x|scaler=${sc}|g" "${conf}/${z}"
    sed -i -e "s|scaler=hq3x|scaler=${sc}|g" "${conf}/${z}"
    sed -i -e "s|scaler=2xsai|scaler=${sc}|g" "${conf}/${z}"
    sed -i -e "s|scaler=super2xsai|scaler=${sc}|g" "${conf}/${z}"
    sed -i -e "s|scaler=advmame2x|scaler=${sc}|g" "${conf}/${z}"
    sed -i -e "s|scaler=advmame3x|scaler=${sc}|g" "${conf}/${z}"
    sed -i -e "s|scaler=tv2x|scaler=${sc}|g" "${conf}/${z}"
    sed -i -e "s|scaler=normal2x|scaler=${sc}|g" "${conf}/${z}"
    cd "${conf}"
done
goto exit && [[ $0 != $BASH_SOURCE ]] && return

: erase
clear
echo ""
echo "Would you like to backup your saves and game settings before you uninstall?"
echo ""
echo "NOTE: If you choose yes, then the next time you install this game, it will ask if you"
echo "would like to restore your saves and settings. These files are stored in your "'!'"save"
echo "folder, in a zip file with the same name as the game."
echo ""
echo "NOTE 2: If you have already backed up previously, this will overwrite your prior save."
echo ""
while true
do
    read -p "[Y]es or [N]o " choice
    case $choice in
        [Yy]* ) errorlevel=1
                break;;
        [Nn]* ) errorlevel=2
                break;;
        [?] ) errorlevel=3
                break;;
        *     ) printf "Invalid input.\n";;
    esac
done

[ $errorlevel == '2' ] && goto delete && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto backup && [[ $0 != $BASH_SOURCE ]] && return

: backup
cd eXoDOS
zip --dif "../eXoDOS/${gamename}.zip" -r ./${gamedir} --out "../eXoDOS/"\!"save/${gamename}.zip"
cd ..

: delete
rm -rf ./eXoDOS/"${gamedir}"/

: end
cd eXoDOS
[ -e unzip.exe ] && rm unzip.exe
goto exit && [[ $0 != $BASH_SOURCE ]] && return

: inprogress
clear
echo ""
echo "You are currently already downloading a game. Please complete that download"
echo "before starting another one."
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"

: exit
[[ $0 != $BASH_SOURCE ]] && return
