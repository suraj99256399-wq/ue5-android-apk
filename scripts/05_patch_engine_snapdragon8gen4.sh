#!/usr/bin/env bash
#
# Teach Unreal Engine 5.0.1 about the Adreno 8xx GPU family (Snapdragon 8 Gen 4
# / Adreno 825, as found in the Oppo K13 Turbo Pro 5G).
#
# UE 5.0 shipped in 2022; its BaseDeviceProfiles.ini stops at the Adreno 7xx
# generation. A GPU the engine does not recognise is not fatal - it falls back
# to the base Android profile - but that fallback is conservative. This script
# mirrors Epic's own Adreno 7xx rules for the 8xx generation, so the device gets
# the Android_High profile and, where Vulkan is available, the Vulkan variant.
#
# Idempotent: re-running is a no-op once the marker is present. A one-time
# backup is written to BaseDeviceProfiles.ini.orig.
#
# Usage:  ./05_patch_engine_snapdragon8gen4.sh [engine_dir]
#
set -euo pipefail

UE_DIR="${1:-$HOME/UnrealEngine}"
PROFILES="$UE_DIR/Engine/Config/BaseDeviceProfiles.ini"
MARKER="Android_Adreno8xx_Vulkan"

[ -f "$PROFILES" ] || { echo "ERROR: $PROFILES not found - run 00_fetch_engine.sh first" >&2; exit 1; }

if grep -q "$MARKER" "$PROFILES"; then
  echo "==> Already patched ($MARKER present) - nothing to do"
  exit 0
fi

echo "==> Patching $PROFILES"
[ -f "$PROFILES.orig" ] || cp "$PROFILES" "$PROFILES.orig"

# 1) Register the new profiles and matching rules inside the existing
#    [Android DeviceProfile] section. The regex mirrors Epic's Adreno 7xx entry
#    with 7 replaced by 8. The doubled backslashes are literal in the engine's
#    own file, so reproduce them exactly.
awk '
  /^\[Android DeviceProfile\]$/ {
    print
    print "+DeviceProfileNameAndTypes=Android_Adreno8xx,Android"
    print "+DeviceProfileNameAndTypes=Android_Adreno8xx_Vulkan,Android"
    print "+MatchProfile=(Profile=\"Android_Adreno8xx_Vulkan\",Match=((SourceType=SRC_GpuFamily,CompareType=CMP_Regex,MatchString=\"Adreno \\\\(TM\\\\) 8[0-9][0-9]\"),(SourceType=SRC_AndroidVersion, CompareType=CMP_Regex,MatchString=\"([0-9]+).*\"),(SourceType=SRC_PreviousRegexMatch,CompareType=CMP_GreaterEqual,MatchString=\"9\"),(SourceType=SRC_VulkanAvailable,CompareType=CMP_Equal,MatchString=\"true\")))"
    print "+MatchProfile=(Profile=\"Android_Adreno8xx\",Match=((SourceType=SRC_GpuFamily,CompareType=CMP_Regex,MatchString=\"Adreno \\\\(TM\\\\) 8[0-9][0-9]\")))"
    next
  }
  { print }
' "$PROFILES.orig" > "$PROFILES"

# 2) Define the profiles themselves, modelled on Android_Adreno7xx.
cat >> "$PROFILES" <<'EOF'

; ---- Adreno 8xx (Snapdragon 8 Gen 4 / Adreno 825)
; Added by 05_patch_engine_snapdragon8gen4.sh
[Android_Adreno8xx DeviceProfile]
DeviceType=Android
BaseProfileName=Android_High

[Android_Adreno8xx_Vulkan DeviceProfile]
DeviceType=Android
BaseProfileName=Android_Adreno8xx
EOF

echo "==> Verifying"
echo "    Adreno8xx references: $(grep -c Adreno8xx "$PROFILES")"
grep -q "$MARKER" "$PROFILES" && echo "    profile section: ok"
grep -q "DeviceProfileNameAndTypes=Android_Adreno8xx,Android" "$PROFILES" && echo "    matching rule: ok"
echo "==> Done. Backup at $PROFILES.orig"
echo "    To revert: cp \"$PROFILES.orig\" \"$PROFILES\""
