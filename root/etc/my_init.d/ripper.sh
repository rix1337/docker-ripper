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

# Ensure KEY is set to the beta key if not provided
if [ -z "$KEY" ]; then
    KEY=$BETA_KEY
    echo "No custom key provided. Using MakeMKV beta key: $KEY"
else
    echo "Using MakeMKV key from ENVIRONMENT variable \$KEY: $KEY"
fi

# Check the current key in settings.conf
CURRENT_KEY=$(grep -oP '(?<=app_Key = ").*(?=")' "$HOME/.MakeMKV/settings.conf" 2>/dev/null || echo "")

if [ "$CURRENT_KEY" == "$KEY" ] || [ "$CURRENT_KEY" == "$BETA_KEY" ]; then
    echo "Key in settings.conf matches the provided key: $CURRENT_KEY"
    echo "Skipping key update..."
else
    echo "Updating MakeMKV registration key..."
    # Ensure the directory exists
    mkdir -p ~/.MakeMKV

    # Update the license key in settings.conf
    echo app_Key = "\"$KEY"\" >"$HOME/.MakeMKV/settings.conf"
    echo "MakeMKV key updated successfully."
fi

# Ensure full permissions on makemkv config
chmod -R 777 ~/.MakeMKV
# Run registration every time
echo "Executing: makemkvcon reg $KEY"
# DO NOT PUT THIS IN DOUBLE QUOTES; ELSE IT WILL FAIL
makemkvcon reg $KEY
# Show content of settings.conf
echo "Showing content of $HOME/.MakeMKV/settings.conf"
cat "$HOME/.MakeMKV/settings.conf"


# Log current registration status
makemkvcon info | grep -i "registration"

# move abcde.conf, if found
if [[ -f /config/abcde.conf ]]; then
    echo "Found abcde.conf."
    cp -f /config/abcde.conf /ripper/abcde.conf
fi

# Check if custom group is set and create it if it doesn't exist
if [ -z ${FILEGROUP+x} ]; then
    echo "Custom group not set, defaulting to users"
    FILEGROUP="users"
else
    echo "Custom group set"
    if [ $(getent group ${FILEGROUP}) ]; then
        echo "Group already exists, skipping."
    else
        if [ -z ${FILEGROUPID+x} ]; then
            FILEGROUPID="4321"
            echo "FILEGROUPID not set, defaulting to ID ${FILEGROUPID}"
        else
            echo "Using custom FILEGROUPID ${FILEGROUPID}"
        fi
        echo "Making custom group ${FILEGROUP} with ID ${FILEGROUPID}"
        groupadd -g ${FILEGROUPID} ${FILEGROUP}
    fi
fi

# Check if custom user is set and create it if it doesn't exist
if [ -z ${FILEUSER+x} ]; then
    echo "Custom user not set, defaulting to nobody"
    FILEUSER="nobody"
else
    echo "Custom user set"
    if id "${FILEUSER}" >/dev/null 2>&1; then
        echo "User already exists, skipping."
    else
        if [ -z ${FILEUSERID+x} ]; then
            FILEUSERID="321"
            echo "FILEUSERID not set, defaulting to ID ${FILEUSERID}"
        else
            echo "Using custom FILEUSERID ${FILEUSERID}"
        fi
        echo "Making custom group ${FILEUSER} with ID ${FILEUSERID}"
        useradd -g ${FILEGROUP} -u ${FILEUSERID} ${FILEUSER}
    fi
fi

# Check if custom permissions are set
if [ -z ${FILEMODE+x} ]; then
    echo "Custom file not permissions set, defaulting to g+rw"
    FILEMODE="g+rw"
else
    echo "Custom file permissions set to ${FILEMODE}"
fi

# permissions
chown -R ${FILEUSER}:${FILEGROUP} /config
chmod -R ${FILEMODE} /config

chmod +x /config/ripper.sh

bash /config/ripper.sh &
