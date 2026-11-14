# ==============================================================================
# FAST BUILD & FLASH FOR ZHILLY AI (COM13 & SD CARD)
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

Write-Host "`n>>> [1/3] Compiling Zhilly AI with live TenClass/Xiaozhi OTA & PIN Audio..." -ForegroundColor Yellow
$env:IDF_PATH = $zhillyIdfPath
$env:IDF_PYTHON_ENV_PATH = Split-Path (Split-Path $zhillyPython -Parent) -Parent
$env:PATH = (Split-Path $zhillyPython -Parent) + ";" + ($toolDirs -join ";") + ";" + $env:PATH

Push-Location "C:\zhilly_build"
& $zhillyPython "$zhillyIdfPath\tools\idf.py" build
if ($LASTEXITCODE -ne 0) { throw "Zhilly AI build failed!" }
Pop-Location
Write-Host "[OK] Zhilly AI binary recompiled successfully!" -ForegroundColor Green

Write-Host "`n>>> [2/3] Updating SD Card and Web Flasher firmware..." -ForegroundColor Yellow
$localSdDir = "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\firmware"
$webFlasherBinDir = "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\bin"
$bruceSrcBin = "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin"
[System.IO.Directory]::CreateDirectory($localSdDir) | Out-Null
Copy-Item "C:\zhilly_build\build\xiaozhi.bin" "$localSdDir\zhilly.bin" -Force
Copy-Item "C:\zhilly_build\build\xiaozhi.bin" "$webFlasherBinDir\zhilly.bin" -Force
if (Test-Path "C:\zhilly_build\build\expression_assets.bin") {
    Copy-Item "C:\zhilly_build\build\expression_assets.bin" "$webFlasherBinDir\expression_assets.bin" -Force
}
if (Test-Path $bruceSrcBin) {
    Copy-Item $bruceSrcBin "$localSdDir\bruce.bin" -Force
}

$sdDrives = @("D", "E", "F")
foreach ($d in $sdDrives) {
    if (Test-Path "$($d):\") {
        Write-Host "Found SD card at $($d):\, syncing Bruce & Zhilly..." -ForegroundColor Green
        [System.IO.Directory]::CreateDirectory("$($d):\firmware") | Out-Null
        [System.IO.Directory]::CreateDirectory("$($d):\zhilly") | Out-Null
        [System.IO.Directory]::CreateDirectory("$($d):\bruce") | Out-Null
        Copy-Item "C:\zhilly_build\build\xiaozhi.bin" "$($d):\firmware\zhilly.bin" -Force
        if (Test-Path $bruceSrcBin) {
            Copy-Item $bruceSrcBin "$($d):\firmware\bruce.bin" -Force
        }
        Copy-Item "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\zhilly\config.json" "$($d):\zhilly\config.json" -Force
        Write-Host "  [OK] $($d):\firmware (bruce.bin + zhilly.bin) & config.json (v2.0.7) updated!" -ForegroundColor Green
    }
}

$targetPort = "COM13"
$pnpPorts = Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "OK" -and ($_.InstanceId -like "*VID_303A*" -or $_.FriendlyName -like "*USB Serial*") }
if ($pnpPorts) {
    if ($pnpPorts[0].FriendlyName -match '\((COM\d+)\)') {
        $targetPort = $matches[1]
        Write-Host "Auto-detected active ESP32 device on port $targetPort!" -ForegroundColor Green
    }
}

Write-Host "`n>>> [3/4] Flashing Bruce (0x20000) + Zhilly AI v1.0.9 (0x990000) + Assets (0xCA0000) to $targetPort..." -ForegroundColor Cyan
& $zhillyPython -m esptool --chip esp32s3 -p $targetPort -b 921600 --before default_reset write_flash --flash_mode dio --flash_freq 80m --flash_size 16MB `
    0x20000 "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin" `
    0x990000 "C:\zhilly_build\build\xiaozhi.bin" `
    0xCA0000 "C:\zhilly_build\build\expression_assets.bin"

Write-Host "`n>>> [4/4] Setting active boot partition to Bruce (ota_0) and resetting..." -ForegroundColor Cyan
$otaTool = "$zhillyIdfPath\components\app_update\otatool.py"
& $zhillyPython $otaTool --port $targetPort switch_ota_partition --slot 0
& $zhillyPython -m esptool --chip esp32s3 -p $targetPort --after hard_reset chip_id > $null 2>&1

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host " DUAL-BOOT (BRUCE + ZHILLY AI v2.0.7) FLASHED! BOOTING TO BRUCE!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
