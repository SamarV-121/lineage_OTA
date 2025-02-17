#!/bin/bash
#
# Copyright © 2022-2025, Samar Vispute "SamarV-121" <samar@samarv121.dev>
#
# SPDX-License-Identifier: Apache-2.0
#
set -e

OTA_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
DEVICES=($*)

logi() { echo -e "\n\033[0;32m$1\033[0m"; }

for DEVICE in "${DEVICES[@]}"; do
    logi "Generating $DEVICE changelog..."
    "$OTA_DIR/scripts/changelog_gen.sh" -d "$DEVICE"

    logi "Uploading $DEVICE OTAs to github"
    TAG="$DEVICE-$(date -u +%Y%m%d_%H%M%S)"
    for BUILD in "$OTA_DIR"/builds/"$DEVICE"/*; do
        "$OTA_DIR/scripts/github-release.sh" -r SamarV-121/lineage_OTA \
            -t "$TAG" -b master -d "Date: $(date)" -f "$BUILD"

        FILENAME=$(basename "$BUILD")
	[[ "$FILENAME"  == *.zip ]] || continue

        BUILD_URL="https://lineage.samarv121.dev/$TAG/$FILENAME"
        if [[ $FILENAME =~ gms ]]; then
            DEVICE_JSON="${DEVICE}_gms.json"
        else
            DEVICE_JSON="${DEVICE}.json"
        fi

        logi "Generating $FILENAME json..."
        "$OTA_DIR/scripts/ota_info_gen.sh" -z "$BUILD" -u "$BUILD_URL" \
            -j "$OTA_DIR/$DEVICE_JSON"
    done
done

logi "Generating platform changelog..."
"$OTA_DIR/scripts/changelog_gen.sh" -p

logi "Committing the changes..."
git -C "$OTA_DIR" add .
git -C "$OTA_DIR" commit -m "OTA: $(date +%F)"
