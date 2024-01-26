#!/bin/bash

RIPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="/config/Ripper.log"

# Startup Info
printf "%s : Starting Ripper. Optical Discs will be detected and ripped within 60 seconds.\n" "$(date "+%d.%m.%Y %T")"

# Set default values for configuration options if not already set
: "${SEPARATERAWFINISH:=true}"
: "${EJECTENABLED:=true}"
: "${JUSTMAKEISO:=false}"
: "${STORAGE_CD:=/out/Ripper/CD}"
: "${STORAGE_DATA:=/out/Ripper/DATA}"
: "${STORAGE_DVD:=/out/Ripper/DVD}"
: "${STORAGE_BD:=/out/Ripper/BluRay}"
: "${DRIVE:=/dev/sr0}"
: "${BAD_THRESHOLD:=5}"

BAD_RESPONSE=0

# Define the drive types and patterns to match against the output of makemkvcon
DRIVE_TYPES=("empty" "open" "loading" "bd1" "bd2" "dvd" "cd1" "cd2")
DRIVE_PATTERNS=(
    'DRV:0,0,999,0,"'
    'DRV:0,1,999,0,"'
    'DRV:0,3,999,0,"'
    'DRV:0,2,999,12,"'
    'DRV:0,2,999,28,"'
    'DRV:0,2,999,1,"'
    'DRV:0,2,999,0,"'
    '","","'$DRIVE'"'
)


# function to cleanup tmp files
cleanup_tmp_files() {
  local tmp_dir="/tmp"
  cd "$tmp_dir" || exit
  rm -rf ./*.tmp 2>/dev/null
  cd - || exit
}


# function to analyze the output of makemkvcon which detects the optical disc type
check_disc() {
    INFO=$(makemkvcon -r --cache=1 info disc:9999 | grep DRV:0)
    EXPECTED=""

    for (( i=0; i<${#DRIVE_TYPES[@]}; i++ )); do
        TYPE=${DRIVE_TYPES[$i]}
        PATTERN=${DRIVE_PATTERNS[$i]}
        MATCH=$(echo $INFO | grep -o "$PATTERN")
        if [[ -n "$MATCH" ]]; then
            declare "$TYPE=$MATCH"
            EXPECTED+="$MATCH"
        fi
    done

    if [[ -z "$EXPECTED" ]]; then
        echo "$(date "+%d.%m.%Y %T") : Unexpected makemkvcon output: $INFO"
        (( BAD_RESPONSE++ ))
    else
        BAD_RESPONSE=0
    fi
}


while true; do
   cleanup_tmp_files
   check_disc
   if (( BAD_RESPONSE >= BAD_THRESHOLD )); then
      echo "$(date "+%d.%m.%Y %T") : Too many errors, ejecting disk and aborting"
      makemkvcon -r --cache=1 info disc:9999
      ejectDisk
   fi
   # get disk info through makemkv and pass output to INFO
   INFO=$"$(makemkvcon -r --cache=1 info disc:9999 | grep DRV:0)"
   # check INFO for optical disk
   EMPTY=$(echo $INFO | grep -o 'DRV:0,0,999,0,"')
   OPEN=$(echo $INFO | grep -o 'DRV:0,1,999,0,"')
   LOADING=$(echo $INFO | grep -o 'DRV:0,3,999,0,"')
   BD1=$(echo $INFO | grep -o 'DRV:0,2,999,12,"')
   BD2=$(echo $INFO | grep -o 'DRV:0,2,999,28,"')
   DVD=$(echo $INFO | grep -o 'DRV:0,2,999,1,"')
   CD1=$(echo $INFO | grep -o 'DRV:0,2,999,0,"')
   CD2=$(echo $INFO | grep -o '","","'$DRIVE'"')

   # Check for trouble and respond if found
   EXPECTED="${EMPTY}${OPEN}${LOADING}${BD1}${BD2}${DVD}${CD1}${CD2}"
   if [ "x$EXPECTED" == 'x' ]; then
      echo "$(date "+%d.%m.%Y %T") : Unexpected makemkvcon output: $INFO"
      let BAD_RESPONSE++
   else
      let BAD_RESPONSE=0
   fi
   if (($BAD_RESPONSE >= $BAD_THRESHOLD)); then
      echo "$(date "+%d.%m.%Y %T") : Too many errors, ejecting disk and aborting"
      # Run makemkvcon once more with full output, to potentially aid in debugging
      makemkvcon -r --cache=1 info disc:9999
      ejectDisk
   fi
   # if [ $EMPTY = 'DRV:0,0,999,0,"' ]; then
   #  echo "$(date "+%d.%m.%Y %T") : No Disc"; &>/dev/null
   # fi
   if [ "$OPEN" = 'DRV:0,1,999,0,"' ]; then
      echo "$(date "+%d.%m.%Y %T") : Disk tray open"
   fi
   if [ "$LOADING" = 'DRV:0,3,999,0,"' ]; then
      echo "$(date "+%d.%m.%Y %T") : Disc still loading"
   fi

   if [ "$BD1" = 'DRV:0,2,999,12,"' ] || [ "$BD2" = 'DRV:0,2,999,28,"' ]; then
      DISKLABEL=$(echo $INFO | grep -o -P '(?<=",").*(?=",")')
      BDPATH="$STORAGE_BD"/"$DISKLABEL"
      BLURAYNUM=$(echo $INFO | grep $DRIVE | cut -c5)
      mkdir -p "$BDPATH"
      ALT_RIP="${RIPPER_DIR}/BLURAYrip.sh"
      if [[ -f $ALT_RIP && -x $ALT_RIP ]]; then
         echo "$(date "+%d.%m.%Y %T") : BluRay detected: Executing $ALT_RIP"
         $ALT_RIP "$BLURAYNUM" "$BDPATH" "$LOGFILE"
      else
         # BluRay/MKV
         echo "$(date "+%d.%m.%Y %T") : BluRay detected: Saving MKV"
         makemkvcon --profile=/config/default.mmcp.xml -r --decrypt --minlength=600 mkv disc:"$BLURAYNUM" all "$BDPATH" >>$LOGFILE 2>&1
      fi
      if [ "$SEPARATERAWFINISH" = 'true' ]; then
         BDFINISH="$STORAGE_BD"/finished/
         mv -v "$BDPATH" "$BDFINISH"
      fi
      echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
      ejectDisk
      # permissions
      chown -R nobody:users "$STORAGE_BD" && chmod -R g+rw "$STORAGE_BD"
   fi

   if [ "$DVD" = 'DRV:0,2,999,1,"' ]; then
      DISKLABEL=$(echo $INFO | grep -o -P '(?<=",").*(?=",")')
      DVDPATH="$STORAGE_DVD"/"$DISKLABEL"
      DVDNUM=$(echo $INFO | grep $DRIVE | cut -c5)
      mkdir -p "$DVDPATH"
      ALT_RIP="${RIPPER_DIR}/DVDrip.sh"
      if [[ -f $ALT_RIP && -x $ALT_RIP ]]; then
         echo "$(date "+%d.%m.%Y %T") : DVD detected: Executing $ALT_RIP"
         $ALT_RIP "$DVDNUM" "$DVDPATH" "$LOGFILE"
      else
         # DVD/MKV
         echo "$(date "+%d.%m.%Y %T") : DVD detected: Saving MKV"
         makemkvcon --profile=/config/default.mmcp.xml -r --decrypt --minlength=600 mkv disc:"$DVDNUM" all "$DVDPATH" >>$LOGFILE 2>&1
      fi
      if [ "$SEPARATERAWFINISH" = 'true' ]; then
         DVDFINISH="$STORAGE_DVD"/finished/
         mv -v "$DVDPATH" "$DVDFINISH"
      fi
      echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
      ejectDisk
      # permissions
      chown -R nobody:users "$STORAGE_DVD" && chmod -R g+rw "$STORAGE_DVD"
   fi

   if [ "$CD1" = 'DRV:0,2,999,0,"' ]; then
      if [ "$CD2" = '","","'$DRIVE'"' ]; then
         ALT_RIP="${RIPPER_DIR}/CDrip.sh"
         if [[ -f $ALT_RIP && -x $ALT_RIP ]]; then
            echo "$(date "+%d.%m.%Y %T") : CD detected: Executing $ALT_RIP"
            $ALT_RIP "$DRIVE" "$STORAGE_CD" "$LOGFILE"
         else
            # MP3 & FLAC
            echo "$(date "+%d.%m.%Y %T") : CD detected: Saving MP3 and FLAC"
            /usr/bin/abcde -d "$DRIVE" -c /ripper/abcde.conf -N -x -l >>$LOGFILE 2>&1
         fi
         echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
         ejectDisk
         # permissions
         chown -R nobody:users "$STORAGE_CD" && chmod -R g+rw "$STORAGE_CD"
      else
         DISKLABEL=$(echo $INFO | grep $DRIVE | grep -o -P '(?<=",").*(?=",")')
         ISOPATH="$STORAGE_DATA"/"$DISKLABEL"/"$DISKLABEL".iso
         mkdir -p "$STORAGE_DATA"/"$DISKLABEL"
         ALT_RIP="${RIPPER_DIR}/DATArip.sh"
         if [[ -f $ALT_RIP && -x $ALT_RIP ]]; then
            echo "$(date "+%d.%m.%Y %T") : Data-Disk detected: Executing $ALT_RIP"
            $ALT_RIP "$DRIVE" "$ISOPATH" "$LOGFILE"
         else
            # ISO
            echo "$(date "+%d.%m.%Y %T") : Data-Disk detected: Saving ISO"
            ddrescue $DRIVE "$ISOPATH" >>$LOGFILE 2>&1
         fi
         echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
         ejectDisk
         # permissions
         chown -R nobody:users "$STORAGE_DATA" && chmod -R g+rw "$STORAGE_DATA"
      fi
   fi
   # Wait a minute
   sleep 1m
done


# function to eject the disk - now with a lower-case function name
ejectdisk() {
   if [[ "$EJECTENABLED" == "true" ]]; then
      if eject -v "$DRIVE" &>/dev/null; then
         printf "Ejecting Disk Succeeded\n"
      else
         printf "%s : Ejecting Disk Failed. Attempting Alternative Method.\n" "$(date "+%d.%m.%Y %T")" >> "$LOGFILE"
         sleep 2
         sdparm --command=unlock "$DRIVE"
         sleep 1
         sdparm --command=eject "$DRIVE"
      fi
   else
      printf "Ejecting Disabled\n"
   fi
}