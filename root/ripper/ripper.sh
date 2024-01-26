#!/bin/bash

RIPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="/config/Ripper.log"

# Startup Info
printf "%s : Starting Ripper. Optical Discs will be detected and ripped within 60 seconds.\n" "$(date "+%d.%m.%Y %T")"

# Set default values for configuration options if not already set
: "${EJECTENABLED:=true}"
: "${JUSTMAKEISO:=false}"
: "${STORAGE_CD:=/out/Ripper/CD}"
: "${STORAGE_DATA:=/out/Ripper/DATA}"
: "${STORAGE_DVD:=/out/Ripper/DVD}"
: "${STORAGE_BD:=/out/Ripper/BluRay}"
: "${DRIVE:=/dev/sr0}"
: "${BAD_THRESHOLD:=5}"
: "${DEBUG:=false}"
# Print the values of configuration options
printf "SEPARATERAWFINISH: %s\n" "$SEPARATERAWFINISH"
printf "EJECTENABLED: %s\n" "$EJECTENABLED"
printf "JUSTMAKEISO: %s\n" "$JUSTMAKEISO"
printf "STORAGE_CD: %s\n" "$STORAGE_CD"
printf "STORAGE_DATA: %s\n" "$STORAGE_DATA"
printf "STORAGE_DVD: %s\n" "$STORAGE_DVD"
printf "STORAGE_BD: %s\n" "$STORAGE_BD"
printf "DRIVE: %s\n" "$DRIVE"
printf "BAD_THRESHOLD: %s\n" "$BAD_THRESHOLD"
printf "DEBUG: %s\n" "$DEBUG"

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

debug_log() {
  if [[ "$DEBUG" == true ]]; then
    echo "[DEBUG] $(date "+%d.%m.%Y %T"): $1" >> "$LOGFILE"
  fi
}

cleanup_tmp_files() {
  debug_log "Cleaning up temporary files."
  local tmp_dir="/tmp"
  cd "$tmp_dir" || exit
  rm -rf ./*.tmp 2>/dev/null
  cd - || exit
  debug_log "Temporary file cleanup completed."
}

check_disc() {
    debug_log "Checking disc."
    INFO=$(makemkvcon -r --cache=1 info disc:9999 | grep DRV:0)
    debug_log "INFO: $INFO"
    EXPECTED=""

    for (( i=0; i<${#DRIVE_TYPES[@]}; i++ )); do
        TYPE=${DRIVE_TYPES[$i]}
        PATTERN=${DRIVE_PATTERNS[$i]}
        MATCH=$(echo $INFO | grep -o "$PATTERN")
        if [[ -n "$MATCH" ]]; then
            declare "$TYPE=$MATCH"
            EXPECTED+="$MATCH"
            debug_log "Detected disc type: $TYPE"
        fi
    done

    if [[ -z "$EXPECTED" ]]; then
        echo "$(date "+%d.%m.%Y %T") : Unexpected makemkvcon output: $INFO"
        debug_log "Unexpected makemkvcon output."
        (( BAD_RESPONSE++ ))
    else
        BAD_RESPONSE=0
    fi
}

handle_bd_disc() {
  local disc_info="$1"
  debug_log "Handling BluRay disc."
  local disc_label="$(echo "$disc_info" | grep -o -P '(?<=",").*(?=",")')"
  local bd_path="$STORAGE_BD/$disc_label"
  local disc_number="$(echo "$disc_info" | grep "$DRIVE" | cut -c5)"
  debug_log "Disc label: $disc_label, Disc number: $disc_number, BD path: $bd_path"
  mkdir -p "$bd_path"
  local alt_rip="${RIPPER_DIR}/BLURAYrip.sh"
  if [[ -f $alt_rip && -x $alt_rip ]]; then
    echo "$(date "+%d.%m.%Y %T") : BluRay detected: Executing $alt_rip"
    debug_log "Executing alternative BluRay rip script."
    $alt_rip "$disc_number" "$bd_path" "$LOGFILE"
  else
    echo "$(date "+%d.%m.%Y %T") : BluRay detected: Saving MKV"
    debug_log "Saving BluRay as MKV."
    makemkvcon --profile=/config/default.mmcp.xml -r --decrypt --minlength=600 mkv disc:"$disc_number" all "$bd_path" >>"$LOGFILE" 2>&1
  fi
  if [ "$SEPARATERAWFINISH" = 'true' ]; then
    local bd_finish="$STORAGE_BD/finished/"
    debug_log "Moving BluRay rip to finished directory: $bd_finish"
    mv -v "$bd_path" "$bd_finish"
  fi
  echo "$(date "+%d.%m.%Y %T") : Done! Ejecting disc"
  ejectdisc
  debug_log "Ejecting BluRay disc."
  chown -R nobody:users "$STORAGE_BD" && chmod -R g+rw "$STORAGE_BD"
  debug_log "Changed owner and permissions for: $STORAGE_BD"
}

handle_dvd_disc() {
  local disc_info="$1"
  debug_log "Handling DVD disc."
  local disc_label="$(echo "$disc_info" | grep -o -P '(?<=",").*(?=",")')"
  local dvd_path="$STORAGE_DVD/$disc_label"
  local disc_number="$(echo "$disc_info" | grep "$DRIVE" | cut -c5)"
  debug_log "Disc label: $disc_label, Disc number: $disc_number, DVD path: $dvd_path"
  mkdir -p "$dvd_path"
  local alt_rip="${RIPPER_DIR}/DVDrip.sh"
  if [[ -f $alt_rip && -x $alt_rip ]]; then
    echo "$(date "+%d.%m.%Y %T") : DVD detected: Executing $alt_rip"
    debug_log "Executing alternative DVD rip script."
    $alt_rip "$disc_number" "$dvd_path" "$LOGFILE"
  else
    echo "$(date "+%d.%m.%Y %T") : DVD detected: Saving MKV"
    debug_log "Saving DVD as MKV."
    makemkvcon --profile=/config/default.mmcp.xml -r --decrypt --minlength=600 mkv disc:"$disc_number" all "$dvd_path" >>"$LOGFILE" 2>&1
  fi
  if [ "$SEPARATERAWFINISH" = 'true' ]; then
    local dvd_finish="$STORAGE_DVD/finished/"
    debug_log "Moving DVD rip to finished directory: $dvd_finish"
    mv -v "$dvd_path" "$dvd_finish"
  fi
  echo "$(date "+%d.%m.%Y %T") : Done! Ejecting disc"
  ejectdisc
  debug_log "Ejecting DVD disc."
  chown -R nobody:users "$STORAGE_DVD" && chmod -R g+rw "$STORAGE_DVD"
  debug_log "Changed owner and permissions for: $STORAGE_DVD"
}

handle_cd_disc() {
  local disc_info="$1"
  debug_log "Handling CD disc."
  local alt_rip="${RIPPER_DIR}/CDrip.sh"
  if [[ -f $alt_rip && -x $alt_rip ]]; then
    echo "$(date "+%d.%m.%Y %T") : CD detected: Executing $alt_rip"
    debug_log "Executing alternative CD rip script."
    $alt_rip "$DRIVE" "$STORAGE_CD" "$LOGFILE"
  else
    echo "$(date "+%d.%m.%Y %T") : CD detected: Saving MP3 and FLAC"
    debug_log "Saving CD as MP3 and FLAC."
    /usr/bin/abcde -d "$DRIVE" -c /ripper/abcde.conf -N -x -l >>"$LOGFILE" 2>&1
  fi
  echo "$(date "+%d.%m.%Y %T") : Done! Ejecting disc"
  ejectdisc
  debug_log "Ejecting CD disc."
  chown -R nobody:users "$STORAGE_CD" && chmod -R g+rw "$STORAGE_CD"
  debug_log "Changed owner and permissions for: $STORAGE_CD"
}

handle_data_disc() {
  local disc_info="$1"
  debug_log "Handling data disc."
  local disc_label="$(echo "$disc_info" | grep "$DRIVE" | grep -o -P '(?<=",").*(?=",")')"
  local iso_path="$STORAGE_DATA/$disc_label/${disc_label}.iso"
  debug_log "Disc label: $disc_label, ISO path: $iso_path"
  mkdir -p "$STORAGE_DATA/$disc_label"
  local alt_rip="${RIPPER_DIR}/DATArip.sh"
  if [[ -f $alt_rip && -x $alt_rip ]]; then
    echo "$(date "+%d.%m.%Y %T") : Data-disc detected: Executing $alt_rip"
    debug_log "Executing alternative DATA disc rip script."
    $alt_rip "$DRIVE" "$iso_path" "$LOGFILE"
  else
    echo "$(date "+%d.%m.%Y %T") : Data-disc detected: Saving ISO"
    debug_log "Saving data-disc as ISO."
    ddrescue "$DRIVE" "$iso_path" >>"$LOGFILE" 2>&1
  fi
  echo "$(date "+%d.%m.%Y %T") : Done! Ejecting disc"
  ejectdisc
  debug_log "Ejecting data disc."
  chown -R nobody:users "$STORAGE_DATA" && chmod -R g+rw "$STORAGE_DATA"
  debug_log "Changed owner and permissions for: $STORAGE_DATA"
}

ejectdisc() {
  debug_log "Ejecting disc from $DRIVE."
  if [[ "$EJECTENABLED" == "true" ]]; then
      if eject -v "$DRIVE" &>/dev/null; then
         printf "Ejecting disc Succeeded\n"
         debug_log "Ejecting disc succeeded."
      else
         printf "%s : Ejecting disc Failed. Attempting Alternative Method.\n" "$(date "+%d.%m.%Y %T")" >> "$LOGFILE"
         debug_log "Ejecting disc failed. Attempting alternative method."
         sleep 2
         sdparm --command=unlock "$DRIVE"
         sleep 1
         sdparm --command=eject "$DRIVE"
      fi
   else
      printf "Ejecting Disabled\n"
      debug_log "Ejecting is disabled."
   fi
}

process_disc_type() {
  debug_log "Processing disc type."
  if [[ -n $empty ]]; then
    echo "$(date "+%d.%m.%Y %T") : No disc inserted."
    debug_log "No disc inserted."
  elif [[ -n $open ]]; then
    echo "$(date "+%d.%m.%Y %T") : Disc tray open."
    debug_log "Disc tray open."
  elif [[ -n $loading ]]; then
    echo "$(date "+%d.%m.%Y %T") : Disc loading."
    debug_log "Disc loading."
  elif [[ -n $bd1 ]] || [[ -n $bd2 ]]; then
    handle_bd_disc "$bd1$bd2"
  elif [[ -n $dvd ]]; then
    handle_dvd_disc "$dvd"
  elif [[ -n $cd1 ]] || [[ -n $cd2 ]]; then
    handle_cd_disc "$cd1$cd2"
  else
    echo "$(date "+%d.%m.%Y %T") : Disc type not recognized."
    debug_log "Disc type not recognized."
  fi
}

launcher_function() {
  debug_log "Starting main function."
  while true; do
    cleanup_tmp_files
    check_disc
    if [ "$BAD_RESPONSE" -lt "$BAD_THRESHOLD" ]; then
        process_disc_type
    else
        echo "$(date "+%d.%m.%Y %T") : Too many bad responses, checking stopped."
        debug_log "Too many bad responses, checking stopped."
        exit 1
    fi
    sleep 1m
  done
}

debug_log "Script start."
launcher_function
