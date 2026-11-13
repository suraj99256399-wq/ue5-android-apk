#!/usr/bin/env bash
#
# Cook, build and package the project as an Android APK.
#
# Usage:
#   ./03_build_apk.sh [engine_dir] [project.uproject] [Shipping|Development]
#
# Example:
#   ./03_build_apk.sh ~/UnrealEngine ./MyGame/MyGame.uproject Shipping
#
# Output:  <project>/Saved/StagedBuilds/Android_ASTC/MyGame.apk
#
set -euo pipefail

UE_DIR="${1:-$HOME/UnrealEngine}"
PROJECT="${2:-$(cd "$(dirname "$0")/.." && pwd)/MyGame/MyGame.uproject}"
CONFIG="${3:-Shipping}"

[ -d "$UE_DIR" ] || { echo "ERROR: engine not found at $UE_DIR" >&2; exit 1; }
[ -f "$PROJECT" ] || { echo "ERROR: project not found at $PROJECT" >&2; exit 1; }
[ -x "$UE_DIR/Engine/Build/BatchFiles/RunUAT.sh" ] || { echo "ERROR: RunUAT.sh missing; build the engine first" >&2; exit 1; }

# shellcheck disable=SC1090
[ -f "$HOME/.ue5-android-env" ] && source "$HOME/.ue5-android-env"

: "${JAVA_HOME:?JAVA_HOME is not set - source ~/.ue5-android-env first}"
: "${ANDROID_HOME:?ANDROID_HOME is not set - source ~/.ue5-android-env first}"
: "${NDKROOT:?NDKROOT is not set - source ~/.ue5-android-env first}"

PROJECT_DIR="$(cd "$(dirname "$PROJECT")" && pwd)"
ARCHIVE_DIR="$PROJECT_DIR/Saved/StagedBuilds"
mkdir -p "$ARCHIVE_DIR"

echo "==> Packaging $PROJECT"
echo "    engine  : $UE_DIR"
echo "    config  : $CONFIG"
echo "    java    : $JAVA_HOME"
echo "    sdk     : $ANDROID_HOME"
echo "    ndk     : $NDKROOT"

"$UE_DIR/Engine/Build/BatchFiles/RunUAT.sh" BuildCookRun \
  -project="$PROJECT" \
  -noP4 -utf8output \
  -platform=Android \
  -cookflavor=ASTC \
  -clientconfig="$CONFIG" \
  -cook -build -stage -package -pak -compressed -archive \
  -archivesdir="$ARCHIVE_DIR" \
  -nocompileeditor

echo
echo "==> APK artifacts:"
find "$PROJECT_DIR/Saved" -name '*.apk' -printf '%10s  %p\n' 2>/dev/null || true
echo
echo "Install on a connected device with:"
echo "    adb install -r <path-to>.apk"
