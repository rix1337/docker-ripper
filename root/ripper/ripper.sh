#!/bin/bash

LOGFILE="/config/Ripper.log"

# Startup Info
echo "$(date "+%d.%m.%Y %T") : Starting Ripper. Optical Discs will be detected and ripped within 60 seconds."

# Paths
STORAGE_MP3="/out/Ripper/CD/MP3"
STORAGE_CD="/out/Ripper/CD/FLAC"
STORAGE_DATA="/out/Ripper/DATA"
STORAGE_DVD="/out/Ripper/DVD"
STORAGE_BD="/out/Ripper/BluRay"
DRIVE="/dev/sr0"

# True is always true, thus loop indefinately
while true
do
# get disk info through makemkv and assing output to INFO
INFO=$"`makemkvcon -r --cache=1 info disc:9999 | grep DRV:0`"
# check INFO for optical disk
EMPTY=`echo $INFO | grep -o 'DRV:0,0,999,0,"'`
OPEN=`echo $INFO | grep -o 'DRV:0,1,999,0,"'`
LOADING=`echo $INFO | grep -o 'DRV:0,3,999,0,"'`
BD=`echo $INFO | grep -o 'DRV:0,2,999,12,"'`
DVD=`echo $INFO | grep -o 'DRV:0,2,999,1,"'`
CD1=`echo $INFO | grep -o 'DRV:0,2,999,0,"'`
CD2=`echo $INFO | grep -o '","","/dev/sr0"'`
DATA=`echo $INFO | grep -o 'DRV:0,2,999,0,"'`

# if [ $EMPTY = 'DRV:0,0,999,0,"' ]; then
#  echo "$(date "+%d.%m.%Y %T") : No Disc"; &>/dev/null
# fi
if [ "$OPEN" = 'DRV:0,1,999,0,"' ]; then
 echo "$(date "+%d.%m.%Y %T") : Disk tray open"
fi
if [ "$LOADING" = 'DRV:0,3,999,0,"' ]; then
 echo "$(date "+%d.%m.%Y %T") : Disc still loading"
fi

if [ "$BD" = 'DRV:0,2,999,12,"' ]; then
 echo "$(date "+%d.%m.%Y %T") : BluRay detected: Saving MKV"
 DISKLABEL=`echo $INFO | grep -o -P '(?<=",").*(?=",")'`
 BDPATH="$STORAGE_BD"/"$DISKLABEL"
 BLURAYNUM=`echo $INFO | grep $DRIVE | cut -c5`
 mkdir -p "$BDPATH"
 makemkvcon -r --decrypt --minlength=600 mkv disc:"$BLURAYNUM" all "$BDPATH" >> $LOGFILE 2>&1
 echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
 eject $DRIVE >> $LOGFILE 2>&1
 # permissions
 chown -R nobody:users /out && chmod -R g+rw /out
fi

if [ "$DVD" = 'DRV:0,2,999,1,"' ]; then
 echo "$(date "+%d.%m.%Y %T") : DVD detected: Saving MKV"
 DISKLABEL=`echo $INFO | grep -o -P '(?<=",").*(?=",")'` 
 DVDPATH="$STORAGE_DVD"/"$DISKLABEL"
 DVDNUM=`echo $INFO | grep $DRIVE | cut -c5`
 mkdir -p "$DVDPATH"
 makemkvcon -r --decrypt --minlength=600 mkv disc:"$DVDNUM" all "$DVDPATH" >> $LOGFILE 2>&1
 echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
 eject $DRIVE >> $LOGFILE 2>&1
 # permissions
 chown -R nobody:users /out && chmod -R g+rw /out
fi

if [ "$CD1" = 'DRV:0,2,999,0,"' ] &&  [ "$CD2" = '","","/dev/sr0"' ]; then
 echo "$(date "+%d.%m.%Y %T") : CD detected: Saving MP3 and FLAC"
 # MP3 & FLAC
 /usr/bin/ripit -d "$DRIVE" -c 0,2 -W -o "$STORAGE_MP3" -b 320 --comment cddbid --playlist 0 -D '"$suffix/$artist/$album"'  --infolog "/log/autorip_"$LOGFILE"" -Z 2 -O y --uppercasefirst --nointeraction >> $LOGFILE 2>&1
 echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
 eject $DRIVE >> $LOGFILE 2>&1
 # permissions
 chown -R nobody:users /out && chmod -R g+rw /out
fi

if [ "$DATA" = 'DRV:0,2,999,0,"' ] &&  ! [ "$CD2" = '","","/dev/sr0"' ]; then
 echo "$(date "+%d.%m.%Y %T") : Data-Disk detected: Saving ISO"
 DISKLABEL=`echo $INFO | grep /dev/sr0 | grep -o -P '(?<=",").*(?=",")'`  
 ISOPATH="$STORAGE_DATA"/"$DISKLABEL/$DISKLABEL".iso
 # ISO
 mkdir -p "$STORAGE_DATA"/"$DISKLABEL"
 ddrescue $DRIVE $ISOPATH >> $LOGFILE 2>&1
 echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
 eject $DRIVE >> $LOGFILE 2>&1
 # permissions
 chown -R nobody:users /out && chmod -R g+rw /out
fi
# Wait a minute
sleep 1m
done
