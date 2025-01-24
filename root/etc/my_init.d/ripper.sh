#!/bin/bash

echo "Using this daily? Please sponsor me at https://github.com/sponsors/rix1337 - any amount counts!"

mkdir -p /config

# copy default script
if [[ ! -f /config/ripper.sh ]]; then
    cp /ripper/ripper.sh /config/ripper.sh
fi

# settings dir
mkdir -p "$HOME/.MakeMKV"

if [[ -f "$HOME/.MakeMKV/settings.conf" ]]; then
    CURRENT_KEY=$(grep -oP 'app_Key = "\K[^"]+' "$HOME/.MakeMKV/settings.conf" 2>/dev/null)
else
    CURRENT_KEY=""
fi

# Grab beta key
BETA_KEY=$(curl --silent 'https://forum.makemkv.com/forum/viewtopic.php?f=5&t=1053' | grep -oP 'T-[\w\d@]{66}')


if [ -n "$KEY" ] && [ "$CURRENT_KEY" == "$KEY" ] || [ "$CURRENT_KEY" == "$BETA_KEY" ]; then
    echo "Key in settings.conf matches the provided key: $CURRENT_KEY"
    echo "Skipping key update..."
else
    if [ -n "$KEY" ]; then
        echo "Using MakeMKV key from ENVIRONMENT variable \$KEY: $KEY"
    else
        KEY=$BETA_KEY
        echo "Using MakeMKV beta key: $KEY"
    fi
    # this sets the license key
    echo app_Key = "\"$KEY"\" >"$HOME/.MakeMKV/settings.conf"
    # this might be optional:
    makemkvcon reg "$KEY"
fi

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
