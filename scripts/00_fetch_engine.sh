#!/usr/bin/env bash
#
# Download the Unreal Engine 5 source archive and extract it.
#
# The archive is a single 37.7 GB zip hosted on archive.org; it expands to
# roughly 131 GB. Both the download and the extraction are resumable, so the
# script can be re-run after an interruption without starting over.
#
# Usage:  ./00_fetch_engine.sh [engine_dir]
#
set -euo pipefail

UE_ZIP_URL="https://ia600406.us.archive.org/4/items/UnrealEngine5Linux/UE5.zip"
UE_DIR="${1:-$HOME/UnrealEngine}"
CACHE_DIR="$HOME/.cache/ue5"
ZIP="$CACHE_DIR/UE5.zip"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' is required but not installed." >&2; exit 1; }; }
need curl
need unzip
need python3

mkdir -p "$CACHE_DIR"

echo "==> Free space check"
avail_kb=$(df -Pk "$(dirname "$UE_DIR")" | awk 'NR==2 {print $4}')
avail_gb=$(( avail_kb / 1024 / 1024 ))
echo "    available on target filesystem: ${avail_gb} GB"
if [ "$avail_gb" -lt 200 ]; then
  echo "    WARNING: extracting the engine needs ~131 GB and a Linux+Android"
  echo "             build needs roughly another 80 GB. 200 GB free is recommended."
fi

echo "==> Downloading engine archive (resumable, ~37.7 GB)"
echo "    $UE_ZIP_URL"
curl -L --fail --retry 10 --retry-delay 5 --retry-all-errors \
     -C - -o "$ZIP" "$UE_ZIP_URL"

echo "==> Verifying archive integrity"
unzip -t "$ZIP" >/dev/null

echo "==> Extracting to $UE_DIR"
mkdir -p "$UE_DIR"
unzip -q -n "$ZIP" -d "$UE_DIR"

echo "==> Engine extracted"
cat "$UE_DIR/Engine/Build/Build.version"
echo
echo "Next:  ./01_setup_android_toolchain.sh \"$UE_DIR\""
