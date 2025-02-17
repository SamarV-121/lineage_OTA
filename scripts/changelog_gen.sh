#!/bin/bash
#
# Copyright © 2022-2025, Samar Vispute "SamarV-121" <samar@samarv121.dev>
#
# SPDX-License-Identifier: Apache-2.0
#
function usage() {
    cat <<EOF
Usage: $0 [options]
Options:
   -p           Generate platform specific changelog
   -d <DEVICE>  Generate device specific changelog
   -O <DIR>     Set output directory
EOF
    exit
}

[ -z "$1" ] && usage

ota_dir=$(dirname "$(dirname "$(readlink -f "$0")")")
root_dir=$(dirname "$ota_dir")
temp_file=$(mktemp)

while getopts ":hd:pO:" opt; do
    case "$opt" in
    d)
        device="$OPTARG"
        changelog_file="$ota_dir/changelog_$device.txt"
        ;;
    p)
        changelog_file="$ota_dir/changelog.txt"
        ;;
    O)
        custom_ota_dir="$OPTARG"
        ;;
    h | *)
        usage
        ;;
    esac
done

[ "$custom_ota_dir" ] && changelog_file="$custom_ota_dir/$changelog_file"

if [ ! -e "$changelog_file" ]; then
    curl -s "https://raw.githubusercontent.com/SamarV-121/lineage_OTA/master/$changelog_file" \
        -o "$changelog_file"
fi

declare -A device_repos=(
    ["m20lte"]="device/samsung/m20lte
                device/samsung/universal7904-common
                device/samsung_slsi/sepolicy
                kernel/samsung/universal7904
                hardware/samsung
                hardware/samsung_slsi/scsc_wifibt/wifi_hal
                hardware/samsung_slsi/libbt
                hardware/samsung_slsi/scsc_wifibt/wpa_supplicant_lib
                hardware/samsung_slsi-linaro/config
                hardware/samsung_slsi-linaro/exynos
                hardware/samsung_slsi-linaro/exynos5
                hardware/samsung_slsi-linaro/graphics
                hardware/samsung_slsi-linaro/interfaces
                hardware/samsung_slsi-linaro/openmax"
    ["RM6785"]="device/realme/RM6785-common
                device/mediatek/sepolicy_vndr
                hardware/mediatek
                kernel/realme/mt6785
                vendor/realme-firmware"
    ["eqe"]="device/motorola/eqe
             kernel/motorola/sm7550
             kernel/motorola/sm7550-modules
             kernel/motorola/sm7550-devicetrees
             hardware/motorola
             system/qcom"
)

function git_log() {
    log=$(
        git -C "$root_dir/$project" log --first-parent \
            --after="$last_date" \
            --abbrev=6 \
            --date=local \
            --format=tformat:"%h %s [%an] (%cd)" |
            grep -v "Automatic translation import"
    )
    if [ -n "$log" ]; then
        echo "$project"
        echo "$project:" >>"$temp_file"
        echo -e "$log\n" >>"$temp_file"
    fi
}

last_date=$(head -n2 "$changelog_file" | tail -n1)
echo -e "==========\n$(date +%F)\n==========" >"$temp_file"

if [[ $device == "RMX2001L1" || $device == "RMX2151L1" ]]; then
    device="RM6785"
fi

if [ "$device" ]; then
    for project in ${device_repos[$device]}; do
        git_log
    done
else
    mapfile -t projects < <(
        {
            awk '/<!-- LineageOS additions -->/,/^$/' "$root_dir/.repo/manifests/snippets/lineage.xml" |
                grep -v crowdin |
                awk -F'[" ]' '/<project/{print $5}'
            grep "LineageOS/" "$root_dir/.repo/manifests/default.xml" |
                grep -v qcom |
                awk -F'[" ]' '/<project/{print $5}'
        } | sort
    )
    for project in "${projects[@]}"; do
        git_log
    done
fi

cat "$temp_file" "$changelog_file" >"$changelog_file.tmp" && mv "$changelog_file.tmp" "$changelog_file"
