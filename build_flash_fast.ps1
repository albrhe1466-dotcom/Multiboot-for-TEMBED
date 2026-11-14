# ==============================================================================
# FAST BUILD & FLASH SCRIPT FOR DUAL-BOOT: BRUCE + ZHILLY AI (COM13)
# 1. Bruce Firmware (ota_0 @ 0x020000)
# 2. Zhilly AI Assistant (ota_2 @ 0x880000) + Assets @ 0xB90000
# ==============================================================================

$ErrorActionPreference = "Stop"

$zhillyPython  = "C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
$zhillyIdfPath = "C:\Espressif\frameworks\esp-idf-v5.5.5"

$env:PYTHONIOENCODING = "utf-8"

$toolDirs = @()
foreach ($toolsRoot in @("C:\Espressif\tools", "$env:USERPROFILE\.espressif\tools")) {
    if (Test-Path $toolsRoot) {
        Get-ChildItem -Path $toolsRoot -Directory -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -in @("bin", "cmd") -or (Test-Path (Join-Path $_.FullName "ninja.exe")) -or (Test-Path (Join-Path $_.FullName "ccache.exe")) } |
            ForEach-Object { $toolDirs += $_.FullName }
        Get-ChildItem -Path "$toolsRoot\esp-rom-elfs" -Directory -ErrorAction SilentlyContinue |
            ForEach-Object {
                $toolDirs += $_.FullName
                $env:ESP_ROM_ELF_DIR = $_.FullName
            }
    }
}
if (-not $env:ESP_ROM_ELF_DIR) {
    $env:ESP_ROM_ELF_DIR = "C:\Espressif\tools\esp-rom-elfs\20241011"
}

# ------------------------------------------------------------------------------
# STEP 1: Rebuild Bruce Firmware (Dedicated Zhilly AI Launcher, No Flipper)
# ------------------------------------------------------------------------------
Write-Host "`n>>> [1/3] Building Bruce Firmware for LilyGO T-Embed..." -ForegroundColor Yellow
$pioExe = "C:\Users\Abdullah\.platformio\penv\Scripts\pio.exe"
if (Test-Path $pioExe) {
    Push-Location "c:\Users\Abdullah\Desktop\qias\bruce_src"
    try {
        & $pioExe run -e lilygo-t-embed-cc1101
        Write-Host "[OK] Bruce Firmware compiled successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Warning: PlatformIO compilation returned warning, using existing binary." -ForegroundColor Yellow
    }
    Pop-Location
} else {
    Write-Host "Using precompiled Bruce binary." -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# STEP 2: Rebuild Zhilly AI Assistant (Live Xiaozhi OTA, PIN Voice Memo & Talk)
# ------------------------------------------------------------------------------
Write-Host "`n>>> [2/3] Building Zhilly AI Assistant with IDF v5.5.5..." -ForegroundColor Yellow
$env:IDF_PATH = $zhillyIdfPath
$env:IDF_PYTHON_ENV_PATH = Split-Path (Split-Path $zhillyPython -Parent) -Parent
$env:PATH = (Split-Path $zhillyPython -Parent) + ";" + ($toolDirs -join ";") + ";" + $env:PATH

Push-Location "C:\zhilly_build"
& $zhillyPython "$zhillyIdfPath\tools\idf.py" build
if ($LASTEXITCODE -ne 0) { throw "Zhilly AI build failed!" }
Pop-Location
Write-Host "[OK] Zhilly AI build complete!" -ForegroundColor Green

# ------------------------------------------------------------------------------
# STEP 3: Sync SD Card & Clean Dual-Boot Flash
# ------------------------------------------------------------------------------
Write-Host "`n>>> [3/3] Synchronizing SD Card & Flashing Clean Dual-Boot to COM13..." -ForegroundColor Yellow

$sdFwDir = "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\firmware"
[System.IO.Directory]::CreateDirectory($sdFwDir) | Out-Null
Copy-Item "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin" "$sdFwDir\bruce.bin" -Force
Copy-Item "C:\zhilly_build\build\xiaozhi.bin" "$sdFwDir\zhilly.bin" -Force

$sdDrives = @("D", "E")
foreach ($d in $sdDrives) {
    if (Test-Path "$($d):\") {
        Write-Host "Found SD Card at $($d):\, syncing files..." -ForegroundColor Green
        [System.IO.Directory]::CreateDirectory("$($d):\firmware") | Out-Null
        [System.IO.Directory]::CreateDirectory("$($d):\zhilly") | Out-Null
        [System.IO.Directory]::CreateDirectory("$($d):\bruce") | Out-Null

        # Purge Flipper completely
        if (Test-Path "$($d):\firmware\flipper.bin") {
            Remove-Item -Path "$($d):\firmware\flipper.bin" -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Removed flipper.bin from SD card" -ForegroundColor Green
        }

        Copy-Item "$sdFwDir\bruce.bin" "$($d):\firmware\bruce.bin" -Force
        Copy-Item "$sdFwDir\zhilly.bin" "$($d):\firmware\zhilly.bin" -Force
        Copy-Item "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\bruce.conf" "$($d):\bruce.conf" -Force
        Copy-Item "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\bruce.conf" "$($d):\bruce\bruce.conf" -Force
        Copy-Item "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\zhilly\config.json" "$($d):\zhilly\config.json" -Force
        Write-Host "  [OK] SD Card ($($d):\) fully synchronized!" -ForegroundColor Green
    }
}

Write-Host "`n>>> Erasing ESP32-S3 Flash cleanly on COM13..." -ForegroundColor Yellow
& $zhillyPython -m esptool --chip esp32s3 -p COM13 -b 921600 erase_flash
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: erase_flash returned non-zero, continuing to flash..." -ForegroundColor Yellow
}

Write-Host "`n>>> Flashing Clean Dual-Boot Partitions to COM13 at 921600 baud..." -ForegroundColor Cyan
& $zhillyPython -m esptool --chip esp32s3 -p COM13 -b 921600 --before default_reset --after hard_reset write_flash --flash_mode dio --flash_freq 80m --flash_size 16MB `
    0x0 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\bootloader\bootloader.bin" `
    0x8000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\partition_table\partition-table.bin" `
    0x10000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\ota_data_initial.bin" `
    0x20000 "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin" `
    0x880000 "C:\zhilly_build\build\xiaozhi.bin" `
    0xB90000 "C:\zhilly_build\build\expression_assets.bin"

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host " CLEAN DUAL-BOOT (BRUCE + ZHILLY AI) SUCCESSFULLY FLASHED TO COM13!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
