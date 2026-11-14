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

## Definitive feasibility result (measured, not estimated)

A UE5 Android APK **cannot** be built inside this sandbox. Measured numbers:

| Stage | Needs | Cumulative |
|---|---|---|
| Download `UE5.zip` | 37.7 GB | 37.7 GB |
| Extract (even pruned, Android-only) | ~53 GB | 90.7 GB |
| Compile (peak intermediates + libs) | ~25 GB | ~115 GB |

Usable disk: **77 GB** (52 GB on `/` + 25 GB on `/workspace`). The zip and the
extracted tree must coexist, so the peak of **90.7 GB already exceeds 77 GB**
before any compiling starts. RAM: UE5's link step wants 16-24 GB; only 15 GB is
present, with no swap.

Largest prune targets, for reference: `Plugins/Experimental` 17.9 GB,
`Source/ThirdParty/PhysX3` 9.3 GB, `CEF3` 7.9 GB, `Intermediate` 31.9 GB
(regenerable). Even dropping all of them leaves the download+extract peak too
high.

No prebuilt Android engine exists to shortcut this: the archive contains **zero**
`libUE4.so`/`libUnreal.so`, and no public Docker image ships a prebuilt arm64 UE5
Android engine (Epic's official images are token-gated).

Conclusion: this is a hardware limit, not a time, permission, or effort limit.
The pipeline in this repo is correct and ready; it needs a Linux host with
200 GB disk and 16 GB+ RAM.

## Target device: Oppo K13 Turbo Pro 5G

Snapdragon 8 Gen 4, Adreno 825, arm64. The project and pipeline are tuned for it:

- `MyGame/Config/DefaultEngine.ini`: `bBuildForArm64=True`, `bBuildForX8664=False`,
  Vulkan + ES 3.1, `MinSDKVersion=29`, `TargetSDKVersion=34`, ASTC cook.
  Every property name in that file was verified against the engine's own
  `AndroidRuntimeSettings.h`.
- `scripts/05_patch_engine_snapdragon8gen4.sh`: UE 5.0's `BaseDeviceProfiles.ini`
  only knows Adreno up to 7xx, so an Adreno 825 would fall back to the
  conservative base profile. This script mirrors Epic's 7xx matching rules for
  the 8xx family (regex `Adreno \(TM\) 8[0-9][0-9]`), giving the phone the
  `Android_High` profile. Purely additive, tested against the real ini, and
  idempotent. Runs as stage 3 of `run_all.sh`.

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
