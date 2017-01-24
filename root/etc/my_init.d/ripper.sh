#!/bin/bash

# copy default script
if [[ ! -f /config/ripper.sh ]]; then
 cp /ripper/ripper.sh /config/ripper.sh
fi

# copy default settings
if [[ ! -f /config/settings.conf ]] && [[  ! -f /config/enter-your-key-then-rename-to.settings.conf ]]; then
 cp -f /ripper/settings.conf /config/
 mv /config/settings.conf /config/enter-your-key-then-rename-to.settings.conf 
fi

# fetching MakeMKV beta key
KEY=$(curl --silent 'http://www.makemkv.com/forum2/viewtopic.php?f=5&t=1053'| grep T-|sed -e 's/.*codecontent..//g' -e 's/..div. .*//g')

# move settings.conf, if found
if [[ -f  /config/settings.conf ]]; then
 echo "Found settings.conf. Replacing beta key file."
 cp -f  /config/settings.conf /root/.MakeMKV/
elif ! [ "$KEY" = '' ]; then
 echo "Using MakeMKV beta key: $KEY"
 touch "/root/.MakeMKV/settings.conf"
 echo app_Key = "\"$KEY"\" > /root/.MakeMKV/settings.conf
fi

# permissions
chown -R nobody:users /config
chmod -R g+rw /config

chmod +x /config/ripper.sh
/config/ripper.sh
