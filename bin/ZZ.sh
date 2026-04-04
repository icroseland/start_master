#!/usr/bin/bash
#curl -L 'https://forge.puppet.com/v3/files/puppetlabs-inifile-5.0.1.tar.gz' | tar -xz -C /tmp/modules/inifile --strip-components=1

set -euo pipefail

YAML_FILE='./list.yaml'
REPO_NAME='https://forge.puppet.com/v3/files/'
DEST_DIR='/tmp/loads'

mkdir -p "$DEST_DIR"

grep -E '^\s*-\s*.*\.tar\.gz$' $YAML_FILE | sed -E 's/^[[:space:]]*-[[:space:]]*//'| while read -r url; do
    echo "XX"
    
    CURRENT_NAME="$REPO_NAME$url"
    DEST_FILE="$DEST_DIR/$url"

    SN1=${url#*-}
    SN2=${SN1%%-*}
    SHORT_NAME=$SN2
    DEST_NAME="$DEST_DIR/$SHORT_NAME"
    echo $SHORT_NAME
    mkdir -p $DEST_NAME
    curl -L --fail  "$CURRENT_NAME" | tar -xz -C $DEST_NAME --strip-components=1
#    tar -xz -C 
    done

