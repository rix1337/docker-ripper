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
: "${DEBUGTOWEB:=false}"
: "${SEPARATERAWFINISH:=true}"
: "${ALSOMAKEISO:=false}"
# Print the values of configuration options if DEBUG is enabled
if [[ "$DEBUG" == true ]]; then
   printf "SEPARATERAWFINISH: %s\n" "$SEPARATERAWFINISH"
   printf "EJECTENABLED: %s\n" "$EJECTENABLED"
   printf "JUSTMAKEISO: %s\n" "$JUSTMAKEISO"
   printf "ALSOMAKEISO: %s\n" "$ALSOMAKEISO"
   printf "STORAGE_CD: %s\n" "$STORAGE_CD"
   printf "STORAGE_DATA: %s\n" "$STORAGE_DATA"
   printf "STORAGE_DVD: %s\n" "$STORAGE_DVD"
   printf "STORAGE_BD: %s\n" "$STORAGE_BD"
   printf "DRIVE: %s\n" "$DRIVE"
   printf "BAD_THRESHOLD: %s\n" "$BAD_THRESHOLD"
   printf "DEBUG: %s\n" "$DEBUG"
   printf "DEBUGTOWEB: %s\n" "$DEBUGTOWEB"
fi

BAD_RESPONSE=0
DISC_TYPE=""
# Define the drive types and patterns to match against the output of makemkvcon
declare -A DRIVE_TYPE_PATTERNS=(
   [empty]='DRV:0,0,999,0,"'
   [open]='DRV:0,1,999,0,"'
   [loading]='DRV:0,3,999,0,"'
   [bd1]='DRV:0,2,999,12,"'
   [bd2]='DRV:0,2,999,28,"'
   [dvd]='DRV:0,2,999,1,"'
   [cd1]='DRV:0,2,999,0,"'
   [cd2]='","","'$DRIVE'"'
)

debug_log() {
   if [[ "$DEBUG" == true ]]; then
      printf "[DEBUG] %s: %s\n" "$(date "+%d.%m.%Y %T")" "$1"
   fi
   if [[ "$DEBUGTOWEB" == true ]]; then
      echo "$(date "+%d.%m.%Y %T"): $1" >>"$LOGFILE"
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
   DISC_TYPE="" # Clear previous disc type value

   for TYPE in "${!DRIVE_TYPE_PATTERNS[@]}"; do
      PATTERN=${DRIVE_TYPE_PATTERNS[$TYPE]}
      if echo "$INFO" | grep -q "$PATTERN"; then
         DISC_TYPE=$TYPE
         debug_log "Detected disc type: $DISC_TYPE"
         break
      fi
   done

   if [[ -z "$DISC_TYPE" ]]; then
      printf "%s : Unexpected makemkvcon output: %s\n" "$(date "+%d.%m.%Y %T")" "$INFO"
      debug_log "Unexpected makemkvcon output."
      ((BAD_RESPONSE++))
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
      printf "%s : BluRay detected: Executing %s\n" "$(date "+%d.%m.%Y %T")" "$alt_rip"
      debug_log "Executing alternative BluRay rip script."
      $alt_rip "$disc_number" "$bd_path" "$LOGFILE"
   else
      printf "%s : BluRay detected: Saving MKV\n" "$(date "+%d.%m.%Y %T")"
      debug_log "Saving BluRay as MKV."
      makemkvcon --profile=/config/default.mmcp.xml -r --decrypt --minlength=600 mkv disc:"$disc_number" all "$bd_path" >>"$LOGFILE" 2>&1
   fi

   move_to_finished "$bd_path" "$STORAGE_BD"
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
      printf "%s : DVD detected: Executing %s\n" "$(date "+%d.%m.%Y %T")" "$alt_rip"
      debug_log "Executing alternative DVD rip script."
      $alt_rip "$disc_number" "$dvd_path" "$LOGFILE"
   else
      printf "%s : DVD detected: Saving MKV\n" "$(date "+%d.%m.%Y %T")"
      debug_log "Saving DVD as MKV."
      makemkvcon --profile=/config/default.mmcp.xml -r --decrypt --minlength=600 mkv disc:"$disc_number" all "$dvd_path" >>"$LOGFILE" 2>&1
   fi

   move_to_finished "$dvd_path" "$STORAGE_DVD"
}

handle_cd_disc() {
   local disc_info="$1"
   debug_log "Handling CD disc."
   local alt_rip="${RIPPER_DIR}/CDrip.sh"
   if [[ -f $alt_rip && -x $alt_rip ]]; then
      printf "%s : CD detected: Executing %s\n" "$(date "+%d.%m.%Y %T")" "$alt_rip"
      debug_log "Executing alternative CD rip script."
      $alt_rip "$DRIVE" "$STORAGE_CD" "$LOGFILE"
   else
      printf "%s : CD detected: Saving MP3 and FLAC\n" "$(date "+%d.%m.%Y %T")"
      debug_log "Saving CD as MP3 and FLAC."
      /usr/bin/abcde -d "$DRIVE" -c /ripper/abcde.conf -N -x -l >>"$LOGFILE" 2>&1
   fi
   printf "%s : Completed CD rip.\n" "$(date "+%d.%m.%Y %T")"
   debug_log "Completed CD rip."
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
   printf "%s : Done saving ISO.\n" "$(date "+%d.%m.%Y %T")"
   debug_log "Done saving ISO."
   chown -R nobody:users "$STORAGE_DATA" && chmod -R g+rw "$STORAGE_DATA"
   debug_log "Changed owner and permissions for: $STORAGE_DATA"
}

move_to_finished() {
   local src_path="$1"
   local dst_root="$2"
   if [ "$SEPARATERAWFINISH" = 'true' ]; then
      local finish_path="${dst_root}/finished/"
      mkdir -p "$finish_path"
      local base_name=$(basename "$src_path")
      finish_path+="$base_name"
      debug_log "Moving ${src_path} to finished directory: ${finish_path}"
      mv -v "$src_path" "$finish_path"
      chown -R nobody:users "$dst_root" && chmod -R g+rw "$dst_root"
      debug_log "Moved $src_path to $finish_path"
   else
      debug_log "SEPARATERAWFINISH is disabled, not moving $src_path"
   fi
}

ejectdisc() {
   if [[ "$EJECTENABLED" == "true" ]]; then
      if eject -v "$DRIVE" &>/dev/null; then
         printf "Ejecting disc Succeeded\n"
         debug_log "Ejecting disc succeeded."
      else
         printf "%s : Ejecting disc Failed. Attempting Alternative Method.\n" "$(date "+%d.%m.%Y %T")" >>"$LOGFILE"
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
   case "$DISC_TYPE" in
   "empty")
      printf "%s : No disc inserted.\n" "$(date "+%d.%m.%Y %T")"
      debug_log "No disc inserted."
      ;;
   "open")
      printf "%s : Disc tray open.\n" "$(date "+%d.%m.%Y %T")"
      debug_log "Disc tray open."
      ;;
   "loading")
      printf "%s : Disc loading.\n" "$(date "+%d.%m.%Y %T")"
      debug_log "Disc loading."
      ;;
   "bd1" | "bd2")
      handle_bd_disc "$INFO"
      ;;
   "dvd")
      handle_dvd_disc "$INFO"
      ;;
   "cd1" | "cd2")
      handle_cd_disc "$INFO"
      ;;
   *)
      printf "%s : Disc type not recognized.\n" "$(date "+%d.%m.%Y %T")"
      debug_log "Disc type not recognized."
      ;;
   esac
}

launcher_function() {
   debug_log "Starting main function."
   while true; do
      cleanup_tmp_files
      check_disc
      if [ "$BAD_RESPONSE" -lt "$BAD_THRESHOLD" ]; then
         if [[ "$JUSTMAKEISO" == "true" ]]; then
            printf "%s : JustMakeISO is enabled. Saving ISO.\n" "$(date "+%d.%m.%Y %T")"
            debug_log "JustMakeISO is enabled. Saving ISO."
            handle_data_disc "$INFO"
         else
            process_disc_type
            if [[ "$ALSOMAKEISO" == "true" ]]; then
               printf "%s : AlsoMakeISO is enabled. Saving ISO.\n" "$(date "+%d.%m.%Y %T")"
               debug_log "AlsoMakeISO is enabled. Saving ISO."
               handle_data_disc "$INFO"
            fi
         fi
      else
         printf "%s : Too many bad responses, checking stopped.\n" "$(date "+%d.%m.%Y %T")"
         debug_log "Too many bad responses, checking stopped."
         exit 1
      fi
      ejectdisc
      sleep 1m # Wait 1 minute before checking for a new disc
   done
}

debug_log "Script start."
launcher_function
