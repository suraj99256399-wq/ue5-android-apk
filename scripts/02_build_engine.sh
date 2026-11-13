#!/usr/bin/env bash
#
# Download engine dependencies and compile the Linux Unreal Editor from source.
#
# This is the long step: Setup.sh pulls ~20 GB of binary dependencies and the
# editor build itself takes 1-3 hours on a fast machine with plenty of RAM.
#
# Usage:  ./02_build_engine.sh [engine_dir]
#
set -euo pipefail

UE_DIR="${1:-$HOME/UnrealEngine}"

[ -d "$UE_DIR" ] || { echo "ERROR: engine not found at $UE_DIR (run 00_fetch_engine.sh first)" >&2; exit 1; }
[ -f "$HOME/.ue5-android-env" ] && source "$HOME/.ue5-android-env"

JOBS="${JOBS:-$(nproc)}"
echo "==> Building Unreal Engine at $UE_DIR using $JOBS jobs"
free -h | head -2

cd "$UE_DIR"

if [ ! -f "Engine/Binaries/DotNET/GitDependencies.exe" ]; then
  echo "ERROR: this does not look like an Unreal Engine source tree." >&2
  exit 1
fi

echo "==> Step 1/3: Setup.sh (download binary dependencies, ~20 GB)"
if [ ! -d "Engine/Binaries/Linux" ] || [ ! -f "Engine/Binaries/ThirdParty/PhysX3/Linux/x86_64-unknown-linux-gnu/libPhysX3.a" ]; then
  ./Setup.sh
else
  echo "    dependencies already present, skipping"
fi

echo "==> Step 2/3: GenerateProjectFiles.sh"
./GenerateProjectFiles.sh

echo "==> Step 3/3: Building UnrealEditor (Linux, Development)"
# Build a monolithic-ish editor for the host platform. This is what the
# BuildCookRun packaging step drives when it compiles the game for Android.
"Engine/Build/BatchFiles/Linux/Build.sh" UnrealEditor Linux Development -waitmutex -progress

if [ -x "Engine/Binaries/Linux/UnrealEditor" ]; then
  echo "==> Editor built: $UE_DIR/Engine/Binaries/Linux/UnrealEditor"
else
  echo "ERROR: editor binary not produced." >&2
  exit 1
fi

echo
echo "Next:  ./03_build_apk.sh \"$UE_DIR\""
