#!/bin/bash

curl -O https://maths-rpi.ddns.net/voidec/downloads/scripts/rebuild.sh
mv rebuild.sh /usr/local/bin/voidec-rebuild
voidec-rebuild generate
