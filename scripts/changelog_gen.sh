#!/bin/bash
#
# Copyright © 2022-2023, Samar Vispute "SamarV-121" <samarvispute121@pm.me>
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

declare -A device_repos=(
	["m20lte"]="device/samsung/m20lte device/samsung/universal7904-common device/samsung_slsi/sepolicy kernel/samsung/universal7904 hardware/samsung hardware/samsung_slsi/scsc_wifibt/wifi_hal hardware/samsung_slsi/libbt hardware/samsung_slsi/scsc_wifibt/wpa_supplicant_lib hardware/samsung_slsi-linaro/config hardware/samsung_slsi-linaro/exynos hardware/samsung_slsi-linaro/exynos5 hardware/samsung_slsi-linaro/graphics hardware/samsung_slsi-linaro/openmax"
	["RM6785"]="device/realme/RM6785-common device/mediatek/sepolicy_vndr hardware/mediatek kernel/realme/mt6785 vendor/realme-firmware"
	# ["RMX2001L1"]="device/realme/RMX2001L1 device/realme/RM6785-common device/mediatek/sepolicy_vndr hardware/mediatek kernel/realme/mt6785 vendor/realme-firmware"
	# ["RMX2151L1"]="device/realme/RMX2151L1 device/realme/RM6785-common device/mediatek/sepolicy_vndr hardware/mediatek kernel/realme/mt6785 vendor/realme-firmware"
)

TEMP_FILE=$(mktemp)

function git_log() {
	LOG=$(git -C "$PROJECT" log --first-parent --after="$LAST_DATE" --abbrev=6 --date=local --format=tformat:"%h %s [%an] (%cd)")
	if [ -n "$LOG" ]; then
		echo "$PROJECT"
		echo "$PROJECT:" >>"$TEMP_FILE"

		if ! [[ $LOG =~ "Automatic translation import" ]]; then
			echo -e "$LOG\n" >>"$TEMP_FILE"
		fi
	fi
}

LAST_DATE=$(head -n2 "$CHANGELOG" | tail -n1)
echo -e "==========\n$(date +%F)\n==========" >"$TEMP_FILE"

if [[ "$DEVICE" == "RMX2001L1" || "$DEVICE" == "RMX2151L1" ]]; then
    DEVICE="RM6785"
fi

if [ "$DEVICE" ]; then
	for PROJECT in ${device_repos[$DEVICE]}; do
		git_log
	done
else
	excluded_repos="extract-utils|crowdin|qcom|ant|json|codeaurora|nxp|lineage/|realme|mediatek|samsung"
	grep -Ev "$excluded_repos" .repo/project.list | while read -r PROJECT; do
		git_log
	done
fi

echo -e "$(cat "$TEMP_FILE" "$CHANGELOG")" >"$CHANGELOG"
