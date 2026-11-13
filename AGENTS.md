# Repository notes

## What this repo is

A pipeline for building an Android APK from Unreal Engine 5 **source code**, plus
a minimal mobile-ready UE5 C++ project (`MyGame/`). See `README.md` for the full
walkthrough.

## Key facts established about the engine source

- Archive item: `UnrealEngine5Linux` on archive.org, single file `UE5.zip`
  (37.7 GB compressed, 130.9 GB uncompressed, 316,103 entries).
- Engine version: **UE 5.0.1**, branch `++UE5+Release-5.0`
  (`Engine/Build/Build.version`).
- The zip is a working tree, **not** a git repo: it contains a populated
  `Engine/Binaries/Linux/` (prebuilt editor binaries) and `Engine/Intermediate/`.
  `.git` holds only `ue4-sdks` blobs, so `Setup.sh`'s git-hook registration is a
  harmless no-op.
- `Engine/Intermediate` (31.8 GB) and `Engine/Plugins` (39.2 GB) dominate the
  extracted size; both are regenerable.

## Android toolchain versions (do not guess these)

Read from `Engine/Source/Programs/UnrealBuildTool/Platform/Android/AndroidPlatformSDK.cs`
and `Engine/Extras/Android/SetupAndroid.sh`:

| Component | Version | Download |
|---|---|---|
| SDK platform | `android-30` | `platform-30_r03.zip` |
| build-tools | `30.0.3` | `build-tools_r30.0.3-linux.zip` |
| NDK | `21.4.7075529` (r21e) | `android-ndk-r21e-linux-x86_64.zip` |
| CMake | `3.10.2.4988404` | via sdkmanager |
| JDK | 8 | Adoptium Temurin 8 |
| Gradle | 6.1.1 | shipped in engine |
| Android Gradle Plugin | 3.5.3 | shipped in engine |

NDK accepted range is r21a–r23a (`AndroidPlatformSDK.cs`). cmdline-tools
`commandlinetools-linux-6200805_latest.zip` works with JDK 8; newer
`11076708` requires JDK 11+.

The engine's own `SetupAndroid.sh` insists on Android Studio being installed.
`01_setup_android_toolchain.sh` deliberately bypasses that and uses the
command-line tools plus a direct NDK download instead.

## Build entry points

- All-in-one: `scripts/run_all.sh` (retries each stage, logs to `build.log`,
  `--skip-engine-build` for the Epic Launcher binary engine)
- Fetch/extract: `scripts/00_fetch_engine.sh`
- Toolchain: `scripts/01_setup_android_toolchain.sh` (writes `~/.ue5-android-env`)
- Engine build: `Setup.sh` → `GenerateProjectFiles.sh` →
  `Engine/Build/BatchFiles/Linux/Build.sh UnrealEditor Linux Development`
- Package: `Engine/Build/BatchFiles/RunUAT.sh BuildCookRun -platform=Android
  -cookflavor=ASTC ...`
- Install: `scripts/04_install_apk.sh`

## Resumability (verified)

Every stage is idempotent, which is what makes `run_all.sh` safe to re-run:

- download: `curl -C -`; archive.org returns HTTP 206 and resumes at the right
  offset (tested: 20 MB partial resumed to 120 MB correctly)
- extract: `unzip -n` skips existing files
- engine build: UnrealBuildTool is incremental
- packaging: overwrites output

## Constraints learned the hard way

- A 25-60 GB / 4-core sandbox **cannot** build this. Engine extraction needs
  131 GB and a Linux + Android build adds ~80 GB. Verified by measuring free
  space (57 GB on `/`, 25 GB on `/workspace`) against the archive listing.
- The archive contains **no Android engine runtime**: `libUE4.so` / `libUnreal.so`
  appear 0 times in the file listing. The only Android-related binaries are
  host-side target-platform plugins in `Engine/Binaries/Linux/Android/` (8 files).
  So the engine must be compiled for arm64 to produce any APK - packaging alone
  cannot work.
- Epic's official `ghcr.io/epicgames/unreal-engine` image is token-gated and
  returns `DENIED` without an Epic-linked GitHub account.
- The `UE5.zip` central directory can be read remotely over HTTP range requests
  (archive.org supports `Accept-Ranges`), which is how the listing was produced
  without a full download. Useful for inspecting the archive cheaply.
- Older Android `commandlinetools-linux-6200805_latest.zip` extracts to a
  `tools/` folder, not `cmdline-tools/`. The setup script handles both layouts.

## Project conventions

- `MyGame` uses the **legacy** input bindings (`InputComponent->BindTouch`), not
  Enhanced Input mapping assets, so it cooks and packages with no editor-authored
  content.
- `APawn::GetMovementComponent()` auto-discovers a `UFloatingPawnMovement` placed
  on the pawn, so `AddMovementInput` works without extra wiring.
- Verified API signatures used: `AHUD::Draw2DLine(int32,int32,int32,int32,FColor)`,
  `AHUD::DrawRect(FLinearColor,float,float,float,float)`,
  `AHUD::Canvas` is `TObjectPtr<UCanvas>`, `FInputTouchBinding& BindTouch(...)`.
- `DefaultEngine.ini` points `GameDefaultMap` at `/Engine/Maps/Templates/OpenWorld`
  so the project runs before any content is authored.

## Testing status

The C++ has **not** been compiled - no toolchain and insufficient disk in this
environment. Brace balance, bash syntax (`bash -n`), and `.uproject` JSON were
validated. Treat first build on a real host as the true compile check.
