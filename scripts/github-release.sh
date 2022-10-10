#!/bin/bash
#
# Copyright © 2021-2022, Samar Vispute "SamarV-121" <samarvispute121@pm.me>
#
# SPDX-License-Identifier: Apache-2.0
#

function usage() {
	cat <<EOF
Usage: $0 [options]
Options:
   -r REPO   <GITHUB_USER/REPO>
   -t TAG
   -b BRANCH
   -d DESCRIPTION
   -f FILES
EOF
	exit "$1"
}

[ -z "$1" ] && usage 0

while getopts ":hr:t:f:d:b:" opt; do
	case "$opt" in
	r)
		REPO="$OPTARG"
		;;
	t)
		TAG="$OPTARG"
		;;
	b)
		BRANCH="$OPTARG"
		;;
	d)
		DESC="$OPTARG"
		;;
	f)
		FILES="$OPTARG"
		;;
	h | *)
		usage 0
		;;
	esac
done

[[ -z $REPO || -z $TAG || -z $BRANCH || -z $DESC || -z $FILES ]] && usage 1

[ -z "$GITHUB_TOKEN" ] && echo "Missing $GITHUB_TOKEN" && exit 1

GITHUB_REPO="https://api.github.com/repos/$REPO"
AUTH="Authorization: token $GITHUB_TOKEN"
TAG_INFO=$(curl -s -H "$AUTH" "$GITHUB_REPO/releases/tags/$TAG")

for FILE in $FILES; do
	if [ ! -f "$FILE" ]; then
		echo "$FILE doesn't exist"
		exit 1
	fi
done

TAG_ID=$(jq .id <<<"$TAG_INFO")
if [ "$TAG_ID" = null ]; then
	TAG_ID=$(curl -X POST "$GITHUB_REPO/releases" -H "$AUTH" -d "{
			\"tag_name\": \"$TAG\",
			\"target_commitish\": \"$BRANCH\",
			\"name\": \"$TAG\",
			\"body\": \"$DESC\"
		}" | jq '.id')
fi

for FILE in $FILES; do
	# Remove old asset with same filename if exists
	ASSET_ID="$(jq -r '.assets[] | select(.name == '\""$FILE"\"').id' <<<"$TAG_INFO" 2>/dev/null)"
	if [ "$ASSET_ID" ]; then
		curl -s -X "DELETE" -H "$AUTH" "$GITHUB_REPO/releases/assets/$ASSET_ID"
	fi
	GITHUB_ASSET="https://uploads.github.com/repos/$REPO/releases/$TAG_ID/assets?name=$(basename "$FILE")"
	echo "Uploading $FILE... "
	LOG=$(curl -T "$FILE" -H "$AUTH" -H "Content-Type: $(file -b --mime-type "$FILE")" "$GITHUB_ASSET")
	DLOAD_URL=$(jq -r '.browser_download_url' <<<"$LOG")
	if [ "$DLOAD_URL" = null ]; then
		echo -e "Failed to upload\n$(<"$LOG")"
	else
		echo -e "Succesfully uploaded\nDownload URL: $DLOAD_URL"
	fi
done
