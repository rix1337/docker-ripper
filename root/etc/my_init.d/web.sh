#!/bin/bash

echo "Starting web ui"

chmod +x /web/web.py
python3 /web/web.py --port=$PORT --prefix=$PREFIX --log=/config/Ripper.log --user=$USER --pass=$PASS
