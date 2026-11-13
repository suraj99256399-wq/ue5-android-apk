#!/usr/bin/env bash
#
# Run the whole pipeline in order and recover from interruptions automatically.
#
# Every stage is idempotent, so this command can be re-run at any time:
#   - the engine download resumes from the last byte received
#   - extraction skips files that already exist
#   - the engine build is incremental
#   - packaging overwrites its previous output
#
# Each stage is retried up to MAX_RETRIES times before giving up, which covers
# dropped connections and transient network failures.
#
# Usage:
#   ./run_all.sh [engine_dir] [project.uproject] [Shipping|Development]
#
# Binary-engine shortcut. If you installed Unreal Engine from the Epic Games
# Launcher, it already ships compiled Android support, so the engine does not
# need to be built. Skip straight to packaging:
#   ./run_all.sh ~/UnrealEngine ./MyGame/MyGame.uproject Shipping --skip-engine-build
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UE_DIR="${1:-$HOME/UnrealEngine}"
PROJECT="${2:-$(cd "$SCRIPT_DIR/.." && pwd)/MyGame/MyGame.uproject}"
CONFIG="${3:-Shipping}"

SKIP_ENGINE_BUILD=0
for arg in "$@"; do
  [ "$arg" = "--skip-engine-build" ] && SKIP_ENGINE_BUILD=1
done

MAX_RETRIES="${MAX_RETRIES:-5}"
RETRY_DELAY="${RETRY_DELAY:-30}"
LOG="$SCRIPT_DIR/../build.log"

run_stage() {
  local name="$1"
  shift
  local attempt=0
  while true; do
    echo
    echo "############ $name ############"
    if "$@"; then
      echo "############ $name: OK ############"
      return 0
    fi
    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$MAX_RETRIES" ]; then
      echo "############ $name: FAILED after $attempt attempts ############"
      return 1
    fi
    echo "!!! $name failed (attempt $attempt/$MAX_RETRIES); retrying in ${RETRY_DELAY}s"
    echo "!!! progress is preserved - already-completed work will be skipped"
    sleep "$RETRY_DELAY"
  done
}

{
  echo "==================================================================="
  echo "UE5 -> Android APK pipeline"
  echo "started : $(date)"
  echo "engine  : $UE_DIR"
  echo "project : $PROJECT"
  echo "config  : $CONFIG"
  echo "==================================================================="

  run_stage "STAGE 1/5  fetch engine source" \
    "$SCRIPT_DIR/00_fetch_engine.sh" "$UE_DIR" || exit 1

  run_stage "STAGE 2/5  android toolchain" \
    "$SCRIPT_DIR/01_setup_android_toolchain.sh" "$UE_DIR" || exit 1

  run_stage "STAGE 3/5  patch engine for Adreno 8xx (Snapdragon 8 Gen 4)" \
    "$SCRIPT_DIR/05_patch_engine_snapdragon8gen4.sh" "$UE_DIR" || exit 1

  if [ "$SKIP_ENGINE_BUILD" -eq 1 ]; then
    echo
    echo "############ STAGE 4/5  engine build: SKIPPED (binary engine) ############"
  else
    run_stage "STAGE 4/5  build engine" \
      "$SCRIPT_DIR/02_build_engine.sh" "$UE_DIR" || exit 1
  fi

  run_stage "STAGE 5/5  package apk" \
    "$SCRIPT_DIR/03_build_apk.sh" "$UE_DIR" "$PROJECT" "$CONFIG" || exit 1

  echo
  echo "==================================================================="
  echo "DONE $(date)"
  echo "APK:"
  find "$(dirname "$PROJECT")/Saved" -name '*.apk' -printf '  %p\n' 2>/dev/null || true
  echo "==================================================================="
} 2>&1 | tee -a "$LOG"

exit "${PIPESTATUS[0]}"
