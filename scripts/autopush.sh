#!/bin/bash
#
# Copyright © 2022, Samar Vispute "SamarV-121" <samarvispute121@pm.me>
#
# SPDX-License-Identifier: Apache-2.0
#
set -e
DEVICES=($*)

logi() { echo -e "\n\033[0;32m$1\033[0m"; }

for DEVICE in "${DEVICES[@]}"; do
	logi "Generating $DEVICE changelog..."
	lineage_OTA/scripts/changelog_gen.sh -d "$DEVICE" -O "lineage_OTA"

	logi "Uploading $DEVICE OTAs to github"
	TAG="$DEVICE-$(date -u +%Y%m%d_%H%M%S)"
	for BUILD in lineage_OTA/builds/*"$DEVICE"*; do
		lineage_OTA/scripts/github-release.sh -r SamarV-121/lineage_OTA -t "$TAG" -b master -d "Date: $(date)" -f "$BUILD"

		FILENAME=$(basename "$BUILD")
		BUILD_URL="https://lineage.samarv121.wtf/$TAG/$FILENAME"
		if [[ $FILENAME =~ gms ]]; then
			DEVICE_JSON="${DEVICE}_gms.json"
		else
			DEVICE_JSON="${DEVICE}.json"
		fi

		logi "Generating $FILENAME json..."
		lineage_OTA/scripts/ota_info_gen.sh -z "$BUILD" -u "$BUILD_URL" -j "lineage_OTA/$DEVICE_JSON"
	done
done

logi "Generating platform changelog..."
lineage_OTA/scripts/changelog_gen.sh -p -O "lineage_OTA"

logi "Committing the changes..."
git -C "lineage_OTA" add .
git -C "lineage_OTA" commit -m "OTA: $(date +%F)"
