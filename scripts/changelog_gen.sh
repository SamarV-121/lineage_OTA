#!/bin/bash
#
# Copyright © 2022, Samar Vispute "SamarV-121" <samarvispute121@pm.me>
#
# SPDX-License-Identifier: Apache-2.0
#
function usage() {
	cat <<EOF
Usage: $0 [options]
Options:
   -p           Generate platform specific changelog
   -d DEVICE    Generate device specific changelog
EOF
	exit
}

[ -z "$1" ] && usage

while getopts ":hd:pO:" opt; do
	case "$opt" in
	d)
		DEVICE="$OPTARG"
		CHANGELOG="changelog_$DEVICE.txt"
		;;
	p)
		CHANGELOG="changelog.txt"
		;;
	O)
		OTA_DIR="$OPTARG"
		;;
	h | *)
		usage
		;;
	esac
done

[ "$OTA_DIR" ] && CHANGELOG="$OTA_DIR/$CHANGELOG"

if [ ! -e "$CHANGELOG" ]; then
	curl -s "https://raw.githubusercontent.com/SamarV-121/lineage_OTA/master/$CHANGELOG" -o "$CHANGELOG"
fi

if [ "$DEVICE" = m20lte ]; then
	device_repos=(
		device/samsung/m20lte
		device/samsung/universal7904-common
		device/samsung_slsi/sepolicy
		kernel/samsung/universal7904
		hardware/samsung
		hardware/samsung_slsi/scsc_wifibt/wifi_hal
		hardware/samsung_slsi/libbt
		hardware/samsung_slsi/scsc_wifibt/wpa_supplicant_lib
	)
elif [ "$DEVICE" = RM6785 ]; then
	device_repos=(
		device/realme/RM6785
		device/mediatek/sepolicy
		kernel/realme/mt6785
		vendor/realme-firmware
	)
fi

TEMP_FILE=$(mktemp)

function git_log() {
	LOG=$(git -C "$PROJECT" log --after="$LAST_DATE" --abbrev=6 --date=local --format=tformat:"%h %s [%an] (%cd)")
	if [ -n "$LOG" ]; then
		echo "$PROJECT"
		echo "$PROJECT:" >>"$TEMP_FILE"
		echo -e "$LOG\n" >>"$TEMP_FILE"
	fi
}

LAST_DATE=$(head -n2 "$CHANGELOG" | tail -n1)
echo -e "==========\n$(date +%F)\n==========" >"$TEMP_FILE"

if [ "$DEVICE" ]; then
	for PROJECT in "${device_repos[@]}"; do
		git_log
	done
else
	excluded_repos="extract-utils|crowdin|qcom|ant|json|codeaurora|nxp|lineage/|realme|mediatek|samsung"
	grep -Ev "$excluded_repos" .repo/project.list | while read -r PROJECT; do
		git_log
	done
fi

echo -e "$(cat "$TEMP_FILE" "$CHANGELOG")" >"$CHANGELOG"
