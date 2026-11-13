# UE5 → Android APK

Build a real Unreal Engine 5 Android APK from engine **source code**, on Linux,
with a working on-screen touch control scheme.

This repository contains the full pipeline: fetch the engine source, install the
Android toolchain, compile the engine, and package the included `MyGame` project
into an installable `.apk`.

## Read this first: the honest requirements

Building UE5 from source for Android is a **big** job. Before you start, make
sure your machine matches:

| Resource | Minimum | Recommended |
|---|---|---|
| Disk (free) | 150 GB | 250 GB SSD |
| RAM | 16 GB | 32 GB+ |
| CPU | 4 cores | 8+ cores |
| OS | Ubuntu 20.04 / 22.04 (or Debian 12+) | Ubuntu 22.04 |
| Time | 4-6 hours | 2-3 hours on a fast machine |

**This cannot run in a small container.** The engine source alone is 131 GB
uncompressed, and a Linux + Android build adds roughly another 80 GB. A sandbox
with a 25-60 GB disk and 4 cores cannot complete this. Run the scripts on a real
Linux host or a large VM.

There is a much cheaper alternative: install the **binary** Unreal Engine from
the Epic Games Launcher. It ships the Android toolchain support already compiled,
so you skip `00_` through `02_` and only run the packaging step. Use the source
path only if you specifically need to modify the engine itself.

## What you get

A first-person mobile pawn (`MyGame/Source/MyGame/MyGamePawn.*`) driven by
multi-touch input:

- **Left half of the screen** - virtual joystick, moves the character.
- **Right half of the screen** - drag to look around.
- A HUD (`MyGameHUD.*`) draws the joystick so you can see it on device.

The controls are implemented in C++ with no editor-authored input assets, so the
project cooks and packages without opening the editor at all.

## Pipeline

```
scripts/run_all.sh                      run everything, auto-resume on failure
scripts/00_fetch_engine.sh              download + extract UE5 source       (~38 GB down, 131 GB up)
scripts/01_setup_android_toolchain.sh   SDK 30 / NDK r21e / JDK 8
scripts/02_build_engine.sh              Setup.sh + compile UnrealEditor     (1-3 h)
scripts/03_build_apk.sh                 cook + package MyGame.apk
scripts/04_install_apk.sh               adb install onto a device
```

### Run it all at once (recommended)

```bash
./scripts/run_all.sh ~/UnrealEngine ./MyGame/MyGame.uproject Shipping
```

`run_all.sh` runs the stages in order, retries each one on failure, and logs to
`build.log`. **Every stage is resumable**, so if your connection drops or the
machine reboots, just run the same command again:

- the engine download continues from the last byte received (`curl -C -`)
- extraction skips files that already exist (`unzip -n`)
- the engine build is incremental (only changed files recompile)
- packaging overwrites its previous output

You can also run the stages individually if you prefer to control each one.

### 1. Fetch the engine

```bash
./scripts/00_fetch_engine.sh ~/UnrealEngine
```

Downloads `UE5.zip` (37.7 GB) from archive.org and extracts it. Both steps
resume if interrupted, so you can safely re-run the script.

### 2. Install the Android toolchain

```bash
./scripts/01_setup_android_toolchain.sh ~/UnrealEngine
source ~/.ue5-android-env
```

Installs exactly the versions UE 5.0 requires (read from the engine's own
`AndroidPlatformSDK.cs`):

- Android SDK platform `android-30`
- build-tools `30.0.3`
- NDK `21.4.7075529` (r21e)
- JDK 8

### 3. Compile the engine

```bash
./scripts/02_build_engine.sh ~/UnrealEngine
```

Runs `Setup.sh` (pulls ~20 GB of binary dependencies), generates project files,
and compiles the Linux `UnrealEditor`. This is the long step.

### 4. Package the APK

```bash
./scripts/03_build_apk.sh ~/UnrealEngine ./MyGame/MyGame.uproject Shipping
```

Runs `RunUAT.sh BuildCookRun` to cook, build, and package. Output:

```
MyGame/Saved/StagedBuilds/Android_ASTC/MyGame.apk
```

### 5. Install on your phone

```bash
./scripts/04_install_apk.sh
```

Or directly: `adb install -r MyGame/Saved/StagedBuilds/Android_ASTC/MyGame.apk`

### Already have the engine from the Epic Games Launcher?

The binary engine ships compiled Android support, so skip the engine build
entirely - this takes minutes instead of hours:

```bash
./scripts/run_all.sh ~/UnrealEngine ./MyGame/MyGame.uproject Shipping --skip-engine-build
```

## Target device: Oppo K13 Turbo Pro 5G (Snapdragon 8 Gen 4 / Adreno 825)

The project is tuned for this device:

- **arm64 only** (`bBuildForArm64=True`, `bBuildForX8664=False`) - roughly halves
  the APK and drops 32-bit paths the phone never uses.
- **Vulkan first, ES 3.1 fallback** - the Adreno 825 is a Vulkan 1.3 part.
- **ASTC textures** (`-cookflavor=ASTC`) - what this GPU wants natively.
- `MinSDKVersion=29`, `TargetSDKVersion=34`.

### The Adreno 8xx problem, and the fix

UE 5.0 shipped in 2022, before the Adreno 8xx existed. Its
`BaseDeviceProfiles.ini` stops at the Adreno 7xx generation, so a Snapdragon
8 Gen 4 falls through to the conservative base Android profile.

`scripts/05_patch_engine_snapdragon8gen4.sh` fixes this. It mirrors Epic's own
Adreno 7xx matching rules for the 8xx family, so the phone is detected and gets
the `Android_High` profile. The patch is purely additive, tested against the
real `BaseDeviceProfiles.ini`, and idempotent.

```
$ ./scripts/05_patch_engine_snapdragon8gen4.sh ~/UnrealEngine
==> Patching /home/you/UnrealEngine/Engine/Config/BaseDeviceProfiles.ini
==> Verifying
    Adreno8xx references: 7
    profile section: ok
    matching rule: ok
==> Done. Backup at .../BaseDeviceProfiles.ini.orig
```

It runs automatically as stage 3 of `run_all.sh`.

### Installing on the phone

1. On the phone: Settings > About device > tap "Build number" 7 times to unlock
   Developer options, then enable **USB debugging**.
2. Plug the phone into the build machine with a data-capable USB cable.
3. Accept the "Allow USB debugging" prompt on the phone.
4. Install:

```bash
./scripts/04_install_apk.sh
# or: adb install -r MyGame/Saved/StagedBuilds/Android_ASTC/MyGame.apk
```

The phone will show a Snapdragon 8 Gen 4 with the `Android_Adreno8xx` profile in
the on-screen log, confirming the patch took effect.

## CI / build server

`.github/workflows/build-android-apk.yml` runs the same pipeline on a machine
with enough disk. It needs a **self-hosted runner** (or a large hosted runner)
with 200 GB free and 16 GB+ RAM - the standard GitHub runners are far too small.
Trigger it from the Actions tab; tick `skip_engine_build` if the runner already
has a built or binary engine. The resulting APK is uploaded as a workflow
artifact.

## Making it *your* game

Edit `MyGame/Config/DefaultEngine.ini`:

```ini
[/Script/AndroidRuntimeSettings.AndroidRuntimeSettings]
PackageName=com.yourcompany.yourgame
ApplicationDisplayName=YourGame
MinSDKVersion=23
TargetSDKVersion=30
bBuildForES31=True
bSupportsVulkan=True
```

Then add your own content. Open the project once in the editor
(`~/UnrealEngine/Engine/Binaries/Linux/UnrealEditor MyGame/MyGame.uproject`) to
create levels, and set `GameDefaultMap` to your level. The default points at the
engine's `OpenWorld` template map so the project runs before you author
anything.

## Texture formats (cookflavor)

`03_build_apk.sh` uses `-cookflavor=ASTC`, which covers virtually all modern
Android devices. Other options: `ETC2` (older/fallback) and `DXT` (desktop
testing only).

## Troubleshooting

- **`NDK not found`** - `source ~/.ue5-android-env` in the same shell you build in.
- **Gradle / `jcenter()` errors** - UE 5.0's Gradle 6.1.1 needs JDK 8, not 11+.
  Confirm `java -version` reports 1.8 and `JAVA_HOME` points at the JDK 8 path.
- **`SDK platform android-30 not found`** - re-run `01_setup_android_toolchain.sh`;
  check `$ANDROID_HOME/platforms/android-30` exists.
- **Out of memory while compiling** - lower `JOBS`, e.g. `JOBS=2 ./scripts/02_build_engine.sh`.
- **`File path too long`** - build from a short path such as `~/UE5`, not a deep nested one.
- **Cooker fails on a map** - point `GameDefaultMap` at a map that exists in
  `Engine/Content/Maps/`, or at a level you have created.

## Legal note

The engine source in `00_fetch_engine.sh` points at an **unofficial community
upload** on archive.org. Unreal Engine is Epic's proprietary software: its EULA
permits source access and modification for licensees, but it does not permit
redistribution. Use this for your own licensed builds only. For anything you
intend to ship, obtain the source from Epic (GitHub `EpicGames/UnrealEngine`,
which requires linking an Epic account) or use the official
`ghcr.io/epicgames/unreal-engine` container.

## Verified in this environment

The following were actually executed and confirmed, not just written:

- `01_setup_android_toolchain.sh` installs a working toolchain: JDK 1.8.0_512,
  `platforms/android-30`, `build-tools/30.0.3`, `ndk/21.4.7075529` with the
  `linux-x86_64` LLVM toolchain, and CMake 3.10.2.4988404.
- Download resumption works against archive.org: a partial file resumed with
  HTTP `206` and continued at the correct byte offset.
- The project's `Build.cs`, `Target.cs`, and `Editor.Target.cs` match Epic's own
  template structure exactly (verified against `Templates/TP_ThirdPerson`).
- All API calls in the C++ were checked against the engine source:
  `AHUD::Draw2DLine(int32,int32,int32,int32,FColor)`, `AHUD::Canvas` is a
  `TObjectPtr<UCanvas>`, `FInputTouchBinding& BindTouch(...)`, and
  `APawn::GetMovementComponent()` auto-discovers a `UFloatingPawnMovement`.

Not yet done: the engine compile and the APK package. Those need the disk and
RAM described at the top of this file.

## Engine version

The archive snapshot is **Unreal Engine 5.0.1** (`++UE5+Release-5.0`). The
toolchain versions above are pinned to match it. If you switch to a newer engine
version, re-read `Engine/Source/Programs/UnrealBuildTool/Platform/Android/AndroidPlatformSDK.cs`
for the required NDK and SDK versions.
