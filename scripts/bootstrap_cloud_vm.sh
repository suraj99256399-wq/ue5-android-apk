#!/usr/bin/env bash
#
# One-command bootstrap for a fresh Ubuntu cloud VM.
#
# Designed for someone who has only a phone: create a free trial VM, open its
# in-browser SSH console, and paste a single command that runs this script.
# It installs every dependency, builds the APK, and then serves it over HTTP so
# the phone's browser can download and install it.
#
# Usage (on the VM):
#   ./scripts/bootstrap_cloud_vm.sh
#
# Optional overrides:
#   UE_DIR=/opt/UnrealEngine PROJECT=/root/ue5-apk/MyGame/MyGame.uproject \
#     ./scripts/bootstrap_cloud_vm.sh
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
UE_DIR="${UE_DIR:-$HOME/UnrealEngine}"
PROJECT="${PROJECT:-$REPO_DIR/MyGame/MyGame.uproject}"
CONFIG="${CONFIG:-Shipping}"
PORT="${PORT:-80}"

echo "=============================================================="
echo " UE5 -> Android APK, one-command cloud build"
echo " repo    : $REPO_DIR"
echo " engine  : $UE_DIR"
echo " project : $PROJECT"
echo "=============================================================="

# --- sanity checks -----------------------------------------------------------
arch="$(uname -m)"
if [ "$arch" != "x86_64" ]; then
  echo "WARNING: this host is $arch, not x86_64."
  echo "         Epic only supports building UE5 on x86_64 Linux. The build may"
  echo "         fail with obscure errors. An x86_64 VM is strongly recommended."
fi

avail_gb=$(df -BG --output=avail "$HOME" | tail -1 | tr -dc '0-9')
echo "Free disk under \$HOME: ${avail_gb} GB"
if [ "${avail_gb:-0}" -lt 200 ]; then
  echo "WARNING: at least 200 GB is recommended. Continuing anyway, but the"
  echo "         engine extraction alone needs ~90 GB."
fi

echo "RAM: $(free -h | awk '/^Mem:/{print $2}')  CPUs: $(nproc)"

# --- host dependencies -------------------------------------------------------
echo
echo "==> Installing host dependencies (needs sudo)"
if ! sudo -n true 2>/dev/null; then
  echo "    sudo will prompt for a password."
fi
sudo apt-get update -qq
sudo apt-get install -y -qq unzip curl git build-essential ca-certificates

# --- build -------------------------------------------------------------------
echo
echo "==> Running the pipeline (this takes hours; safe to re-run if interrupted)"
"$SCRIPT_DIR/run_all.sh" "$UE_DIR" "$PROJECT" "$CONFIG" || {
  echo
  echo "Pipeline exited non-zero. If it was an interruption, just re-run:"
  echo "    $SCRIPT_DIR/bootstrap_cloud_vm.sh"
  echo "Progress is preserved and it resumes where it stopped."
  exit 1
}

# --- hand the APK to the phone ----------------------------------------------
APK="$(find "$(dirname "$PROJECT")/Saved/StagedBuilds" -name '*.apk' 2>/dev/null | head -n 1)"
if [ -z "$APK" ]; then
  echo "ERROR: build finished but no APK was found" >&2
  exit 1
fi

IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
echo
echo "=============================================================="
echo " DONE"
echo " APK : $APK"
echo " Size: $(du -h "$APK" | cut -f1)"
echo "=============================================================="
echo
echo "TWO ways to get the APK onto your phone:"
echo
echo "  1) Easiest - browser SSH file download:"
echo "     In the Google Cloud 'SSH' window, click the gear icon (top right)"
echo "     and choose 'Download file'. Enter this path:"
echo "         $APK"
echo
echo "  2) Over the network (needs the VM's firewall to allow the port):"
echo "         http://${IP}:${PORT}/$(basename "$APK")"
echo "     On Google Cloud, tick 'Allow HTTP traffic' when creating the VM"
echo "     so port 80 is reachable. Allow 'Install unknown apps' in your"
echo "     phone's browser when prompted."
echo
echo "Remember to STOP or DELETE this VM afterwards so it stops costing credit."
echo

cd "$(dirname "$APK")"
if [ "$PORT" -lt 1024 ]; then
  echo "Starting web server on port $PORT (needs sudo). Ctrl+C to stop."
  exec sudo python3 -m http.server "$PORT"
else
  echo "Starting web server on port $PORT. Ctrl+C to stop."
  exec python3 -m http.server "$PORT"
fi
