#!/bin/bash

echo "Starting web ui"

chmod +x /web/web.py
python3 /web/web.py --port=9090 --prefix=$OPTIONAL_WEB_UI_PATH_PREFIX --log=/config/Ripper.log --user=$OPTIONAL_WEB_UI_USERNAME --pass=$OPTIONAL_WEB_UI_PASSWORD
