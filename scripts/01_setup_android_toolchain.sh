#!/usr/bin/env bash
#
# Install the Android toolchain that Unreal Engine 5.0 requires.
#
# Versions are taken from the engine's own build code:
#   Engine/Source/Programs/UnrealBuildTool/Platform/Android/AndroidPlatformSDK.cs
#   Engine/Extras/Android/SetupAndroid.sh
#
#   SDK platform .... android-30
#   build-tools ..... 30.0.3
#   NDK ............. 21.4.7075529  (r21e)
#   Gradle .......... 6.1.1
#   AGP ............. 3.5.3
#   Java ............ 8
#
# Usage:  ./01_setup_android_toolchain.sh [engine_dir]
#
set -euo pipefail

UE_DIR="${1:-$HOME/UnrealEngine}"
SDK_ROOT="${ANDROID_HOME:-$HOME/Android/Sdk}"
JDK_DIR="$HOME/.cache/ue5/jdk8"

PLATFORM="android-30"
BUILD_TOOLS="30.0.3"
NDK_VERSION="21.4.7075529"
CMAKE_VERSION="3.10.2.4988404"

REPO="https://dl.google.com/android/repository"
CMDLINE_TOOLS_ZIP="commandlinetools-linux-6200805_latest.zip"
NDK_ZIP="android-ndk-r21e-linux-x86_64.zip"
PLATFORM_ZIP="platform-30_r03.zip"
BUILD_TOOLS_ZIP="build-tools_r30.0.3-linux.zip"
JDK_URL="https://api.adoptium.net/v3/binary/latest/8/ga/linux/x64/jdk/hotspot/normal/eclipse"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' is required." >&2; exit 1; }; }
need curl
need unzip

mkdir -p "$SDK_ROOT" "$JDK_DIR"

echo "==> Installing Java 8 (required by the UE 5.0 Android toolchain)"
if [ ! -x "$JDK_DIR/bin/java" ]; then
  tmp=$(mktemp -d)
  curl -L --fail --retry 5 -o "$tmp/jdk8.tar.gz" "$JDK_URL"
  mkdir -p "$JDK_DIR"
  tar -xzf "$tmp/jdk8.tar.gz" -C "$JDK_DIR" --strip-components=1
  rm -rf "$tmp"
fi
export JAVA_HOME="$JDK_DIR"
export PATH="$JAVA_HOME/bin:$PATH"
java -version

echo "==> Installing Android SDK command-line tools"
if [ ! -x "$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
  tmp=$(mktemp -d)
  curl -L --fail --retry 5 -o "$tmp/cmdline-tools.zip" "$REPO/$CMDLINE_TOOLS_ZIP"
  mkdir -p "$SDK_ROOT/cmdline-tools/latest"
  unzip -q "$tmp/cmdline-tools.zip" -d "$SDK_ROOT/cmdline-tools/latest"
  # Older zips nest everything under "tools/", newer ones under "cmdline-tools/".
  # sdkmanager must end up directly in cmdline-tools/latest/bin.
  for nested in cmdline-tools tools; do
    if [ -d "$SDK_ROOT/cmdline-tools/latest/$nested" ]; then
      mv "$SDK_ROOT/cmdline-tools/latest/$nested"/* "$SDK_ROOT/cmdline-tools/latest/"
      rmdir "$SDK_ROOT/cmdline-tools/latest/$nested"
      break
    fi
  done
  rm -rf "$tmp"
fi

SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
export ANDROID_HOME="$SDK_ROOT"
export ANDROID_SDK_ROOT="$SDK_ROOT"

echo "==> Accepting SDK licenses"
yes | "$SDKMANAGER" --sdk_root="$SDK_ROOT" --licenses >/dev/null 2>&1 || true

echo "==> Installing platform-tools, $PLATFORM and build-tools $BUILD_TOOLS"
"$SDKMANAGER" --sdk_root="$SDK_ROOT" "platform-tools" "platforms;$PLATFORM" "build-tools;$BUILD_TOOLS"

echo "==> Installing CMake $CMAKE_VERSION"
"$SDKMANAGER" --sdk_root="$SDK_ROOT" "cmake;$CMAKE_VERSION" || \
  echo "    (CMake $CMAKE_VERSION is optional; NDK builds use the shipped toolchain file)"

echo "==> Installing Android NDK $NDK_VERSION"
if [ ! -d "$SDK_ROOT/ndk/$NDK_VERSION" ]; then
  tmp=$(mktemp -d)
  curl -L --fail --retry 5 -o "$tmp/ndk.zip" "$REPO/$NDK_ZIP"
  unzip -q "$tmp/ndk.zip" -d "$tmp/ndk"
  mkdir -p "$SDK_ROOT/ndk"
  mv "$tmp/ndk"/* "$SDK_ROOT/ndk/$NDK_VERSION"
  rm -rf "$tmp"
fi

echo "==> Writing environment file: $HOME/.ue5-android-env"
cat > "$HOME/.ue5-android-env" <<EOF
export JAVA_HOME="$JDK_DIR"
export ANDROID_HOME="$SDK_ROOT"
export ANDROID_SDK_ROOT="$SDK_ROOT"
export NDKROOT="$SDK_ROOT/ndk/$NDK_VERSION"
export PATH="\$JAVA_HOME/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH"
EOF
# shellcheck disable=SC1090
source "$HOME/.ue5-android-env"

echo "==> Verifying toolchain"
[ -x "$ANDROID_HOME/platform-tools/adb" ] && echo "    adb .......... ok" || echo "    adb .......... MISSING"
[ -d "$ANDROID_HOME/platforms/$PLATFORM" ] && echo "    $PLATFORM ... ok" || echo "    $PLATFORM ... MISSING"
[ -d "$ANDROID_HOME/build-tools/$BUILD_TOOLS" ] && echo "    build-tools .. ok" || echo "    build-tools .. MISSING"
[ -d "$NDKROOT/toolchains/llvm" ] && echo "    NDK .......... ok ($NDK_VERSION)" || echo "    NDK .......... MISSING"

echo
echo "Toolchain ready. Source it in new shells with:"
echo "    source ~/.ue5-android-env"
echo
echo "Next:  ./02_build_engine.sh \"$UE_DIR\""
