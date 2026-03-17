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

restore=N
clear
cd "${folder}"
conf="${PWD}"
cd ..
cd ..
cd ..
cd ..
. "./util/${languagefolder}/texts_linux.txt"
grep -q "^${gamename}" "./util/${languagefolder}/multilanguage.txt" && mla=yes

[ -e ./eXoDOS/"${languagefolder}"/"${gamedir}"/ ] && goto dele && [[ $0 != $BASH_SOURCE ]] && return
: unzip
[ "${mla}" = "" ] && goto nomla && [[ $0 != $BASH_SOURCE ]] && return
#if it is multilanguage we need to get the gamezip from basepack and unpack it
[ -e ./eXoDOS/"${gamename}".zip ] && goto mlanext && [[ $0 != $BASH_SOURCE ]] && return
#if base pack gamezip not downloaded yet, we need to grab it and it's metadata zip
clear
#get gamezip download file
fullindex=`grep ":${gamename}" ./util/aria/index.txt | tail -1 | tr -d "\r"`
filesize1="${fullindex#*:}"
filesize="${filesize1#*:}"
echo "filesize is ${filesize}"
removeindex="${fullindex#*:}"
result="$(printf '%s\n' "${fullindex//$removeindex}")"
index="${result::-1}"
#get game meta zip download file
fullindex2=`grep ":GameData/eXoDOS/${gamename}" ./util/aria/index.txt | tail -1 | tr -d "\r"`
removeindex2="${fullindex2#*:}"
result2="$(printf '%s\n' "${fullindex2//$removeindex2}")"
index2="${result2::-1}"
clear
echo ""
echo "${line0109}"
echo "${line0110}"
echo "${line0111} ${filesize}"
echo ""
echo "${line0112}"
echo "${line0113}"
echo ""
dynchoice "${line0114}" "${line0115}"

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
[ -e "${gamename}".zip ] && echo "${line0118}"
[ ! -e "${gamename}".zip ] && echo "${line0119}"
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"
cd ..
clear

: mlanext
unzip -o ./eXoDOS/"${gamename}".zip -d ./eXoDOS/"${languagefolder}"/

: nomla
[ "${mla}" == "yes" ] && goto nocheck && [[ $0 != $BASH_SOURCE ]] && return
[ ! -e ./eXoDOS/"${languagefolder}"/"${gamename}".zip ] && goto exit && [[ $0 != $BASH_SOURCE ]] && return
: nocheck
[ ! -e ./eXoDOS/"${languagefolder}"/\!save/"${gamename}".zip ] && goto unzip2 && [[ $0 != $BASH_SOURCE ]] && return
clear
echo ""
echo "${line0045}"
echo ""
dynchoice "${line0046}" "${line0047}"

[ $errorlevel == '3' ] && goto remove && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto unzip2 && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto restore && [[ $0 != $BASH_SOURCE ]] && return

: remove
rm ./eXoDOS/"${languagefolder}"/\!save/"${gamename}".zip
goto unzip2 && [[ $0 != $BASH_SOURCE ]] && return

: restore
restore=Y

: unzip2
unzip -o ./eXoDOS/"${languagefolder}"/"${gamename}".zip -d ./eXoDOS/"${languagefolder}"/
[ "${restore}" == Y ] && unzip -o ./eXoDOS/"${languagefolder}"/\!save/"${gamename}".zip -d ./eXoDOS/"${languagefolder}"/
runupdate=N
[ -e ./Update/\!dos/"${languagefolder}"/"${gamename}".zip ] && runupdate=Y
[ -e ./Update/\!dos/"${languagefolder}"/linux/release/"${gamename}".zip ] && runupdate=Y
[ -e ./Update/\!dos/"${languagefolder}"/linux/"${gamename}".zip ] && runupdate=Y
[ "${runupdate}" == N ] && goto config && [[ $0 != $BASH_SOURCE ]] && return

clear
echo ""
echo "${line0048}"
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"
[ -e ./Update/\!dos/"${languagefolder}"/"${gamename}".zip ] && unzip -o ./Update/\!dos/"${languagefolder}"/"${gamename}".zip -d ./eXoDOS/"${languagefolder}"/
[ -e ./Update/\!dos/"${languagefolder}"/linux/release/"${gamename}".zip ] && unzip -o ./Update/\!dos/"${languagefolder}"/linux/release/"${gamename}".zip -d ./eXoDOS/"${languagefolder}"/
[ -e ./Update/\!dos/"${languagefolder}"/linux/"${gamename}".zip ] && unzip -o ./Update/\!dos/"${languagefolder}"/linux/"${gamename}".zip -d ./eXoDOS/"${languagefolder}"/

goto config && [[ $0 != $BASH_SOURCE ]] && return
: dele
clear
echo ""
echo "${line0049}"
echo ""
echo "${line0050}"
echo "${line0051}"
echo ""
dynchoice "${line0052}" "${line0053}"

[ $errorlevel == '2' ] && goto erase && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto config && [[ $0 != $BASH_SOURCE ]] && return
: config
[ ! -e ./eXoDOS/"${languagefolder}"/"${gamedir}"/ ] && goto exit && [[ $0 != $BASH_SOURCE ]] && return
clear
echo ""
echo "${line0004}"
echo ""
[ -e ./util/WIN.SEL ] && echo "${line0054}"
[ -e ./util/FULL.SEL ] && echo "${line0055}"
[ -e ./util/MED.SEL ] && echo "${line0056}"
[ -e ./util/SML.SEL ] && echo "${line0057}"
[ -e ./util/LRG.SEL ] && echo "${line0058}"
[ -e ./util/ANO.SEL ] && echo "${line0059}"
[ -e ./util/AYES.SEL ] && echo "${line0060}"
echo ""
echo "${line0005}"
echo ""
echo "${line0063}"
echo "${line0064}"
echo ""
dynchoice "${line0061}" "${line0062}"

[ $errorlevel == '3' ] && goto whatglob && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto scaler1 && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto aspect && [[ $0 != $BASH_SOURCE ]] && return

: whatglob
clear
echo ""
echo "${line0065}"
echo "${line0066}"
echo "${line0067}"
echo ""
echo "${line0068}"
echo "${line0069}"
echo "${line0070}"
echo "${line0071}"
echo "${line0072}"
echo ""
echo "${line0073}"
echo "${line0074}"
echo "${line0075}"
echo "${line0076}"
echo "${line0077}"
echo "${line0078}"
echo "${line0079}"
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"
goto config && [[ $0 != $BASH_SOURCE ]] && return

: aspect
scriptDirStack["${#scriptDirStack[@]}"]="$scriptDir"
eval source ./emulators/dosbox/\!languagepacks/config.bsh
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
echo "${line0008}"
echo ""
echo "${line0080}"
echo ""
dynchoice "${line0061}" "${line0062}"

[ $errorlevel == '3' ] && goto whatsy && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '2' ] && goto end && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto sy && [[ $0 != $BASH_SOURCE ]] && return

: whatsy
clear
echo ""
echo "${line0081}"
echo ""
echo "${line0082}"
echo "${line0083}"
echo ""
echo "${line0084}"
echo "${line0085}"
echo "${line0086}"
echo ""
echo "${line0087}"
echo "${line0088}"
echo "${line0089}"
echo "${line0090}"
echo "${line0091}"
echo "${line0092}"
echo "${line0093}"
echo "${line0094}"
echo ""
echo "${line0095}"
echo "${line0096}"
echo "${line0097}"
echo "${line0098}"
echo "${line0099}"
echo ""
echo "${line0100}"
echo "${line0101}"
echo "${line0102}"
echo ""
echo "${line0103}"
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"
goto scaler1 && [[ $0 != $BASH_SOURCE ]] && return

: sy
clear
echo ""
echo "${line0009}"
echo " 1  ${line0010}"
echo " 2  normal3x"
echo " 3  hq2x"
echo " 4  hq3x"
echo " 5  2xsai"
echo " 6  super2xsai"
echo " 7  advmame2x"
echo " 8  advmame3x"
echo " 9  tv2x"
echo " 0  normal2x"
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
cd ..
cd ..
cd ..
goto end && [[ $0 != $BASH_SOURCE ]] && return

: erase
clear
echo ""
echo "${line0104}"
echo ""
echo "${line0105}"
echo "${line0106}"
echo "${line0107}"
echo ""
echo "${line0108}"
echo ""
dynchoice "${line0006}" "${line0007}"

[ $errorlevel == '2' ] && goto delete && [[ $0 != $BASH_SOURCE ]] && return
[ $errorlevel == '1' ] && goto backup && [[ $0 != $BASH_SOURCE ]] && return

: backup
cd eXoDOS
cd "${languagefolder}"
zip --dif "../../eXoDOS/${languagefolder}/${gamename}.zip" -r ./${gamedir} --out "../../eXoDOS/${languagefolder}/"\!"save/${gamename}.zip"
cd ..
cd ..

: delete
rm -rf ./eXoDOS/"${languagefolder}"/"${gamedir}"/

: end
cd eXoDOS
cd "${languagefolder}"
[ -e unzip.exe ] && rm unzip.exe
goto exit && [[ $0 != $BASH_SOURCE ]] && return

: inprogress
clear
echo ""
echo "${line0116}"
echo "${line0117}"
echo ""
read -s -n 1 -p "Press any key to continue..."
printf "\n\n"

: exit
[[ $0 != $BASH_SOURCE ]] && return
