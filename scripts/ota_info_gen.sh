#!/bin/bash
#
# Copyright © 2021-2024, Samar Vispute "SamarV-121" <samar@samarv121.dev>
#
# SPDX-License-Identifier: Apache-2.0
#
set -e

function usage() {
    echo -e "Usage: $0 -z <ZIP_PATH> -u <RELEASE_URL>"
    exit "$1"
}

[ -z "$1" ] && usage

while getopts ":hz:u:j:" opt; do
    case "$opt" in
    z)
        ZIP_PATH="$OPTARG"
        ;;
    u)
        RELEASE_URL="$OPTARG"
        ;;
    j)
        JSON="$OPTARG"
        ;;
    h | *)
        usage
        ;;
    esac
done

[[ -z $ZIP_PATH || -z $RELEASE_URL ]] && usage 1

TEMP_FILE=$(mktemp)

TIMESTAMP=$(unzip -p "$ZIP_PATH" META-INF/com/android/metadata | grep timestamp | awk -F'=' '{print $2}')
FILENAME=$(basename "$ZIP_PATH")
ID=$(sha256sum <<<"$FILENAME" | awk '{print $1}')
SIZE=$(stat -c '%s' "$ZIP_PATH")
VERSION=$(awk -F'-' '{print $2}' <<<"$FILENAME")
TYPE=$(awk -F'-' '{print $4}' <<<"$FILENAME")

cat <<EOF >"$TEMP_FILE"
{
  "response": [
    {
      "datetime": $TIMESTAMP,
      "filename": "$FILENAME",
      "id": "$ID",
      "romtype": "$TYPE",
      "size": $SIZE,
      "url": "$RELEASE_URL",
      "version": "$VERSION"
    }
  ]
}
EOF
jq <"$TEMP_FILE" &&
    [ "$JSON" ] && cp "$TEMP_FILE" "$JSON"
