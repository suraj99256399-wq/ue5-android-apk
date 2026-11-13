#!/usr/bin/env bash
#
# Install the packaged APK onto a connected Android device.
#
# Usage:  ./04_install_apk.sh [project.uproject]
#
set -euo pipefail

PROJECT="${1:-$(cd "$(dirname "$0")/.." && pwd)/MyGame/MyGame.uproject}"

# shellcheck disable=SC1090
[ -f "$HOME/.ue5-android-env" ] && source "$HOME/.ue5-android-env"

command -v adb >/dev/null 2>&1 || { echo "ERROR: adb not found - source ~/.ue5-android-env" >&2; exit 1; }

APK="$(find "$(dirname "$PROJECT")/Saved/StagedBuilds" -name '*.apk' 2>/dev/null | head -n 1)"
[ -n "$APK" ] || { echo "ERROR: no APK found - run 03_build_apk.sh first" >&2; exit 1; }

echo "==> Devices:"
adb devices

echo "==> Installing $APK"
adb install -r "$APK"
echo "==> Installed."
