#!/bin/bash

echo "Using this daily? Please sponsor me at https://github.com/sponsors/rix1337 - any amount counts!"

mkdir -p /config

# copy default script
if [[ ! -f /config/ripper.sh ]]; then
    cp /ripper/ripper.sh /config/ripper.sh
fi

# key setup logic
mkdir -p /root/.MakeMKV
if [ -n "$KEY" ]; then
    echo "Using MakeMKV key from ENVIRONMENT variable \$KEY: $KEY"
else
    KEY=$(curl --silent 'https://forum.makemkv.com/forum/viewtopic.php?f=5&t=1053' | grep -oP 'T-[\w\d@]{66}')
    echo "Using MakeMKV beta key: $KEY"
fi

echo app_Key = "\"$KEY"\" >/root/.MakeMKV/settings.conf
makemkvcon reg "$KEY"

# move abcde.conf, if found
if [[ -f /config/abcde.conf ]]; then
    echo "Found abcde.conf."
    cp -f /config/abcde.conf /ripper/abcde.conf
fi

# permissions
chown -R nobody:users /config
chmod -R g+rw /config

chmod +x /config/ripper.sh

bash /config/ripper.sh &
