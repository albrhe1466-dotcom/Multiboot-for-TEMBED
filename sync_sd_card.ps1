# ==============================================================================
# DEEP CLEAN & SYNC SD CARD FOR BRUCE + ZHILLY AI (FLIPPER PURGE)
# ==============================================================================
param(
    [string]$DriveLetter = ""
)

$ErrorActionPreference = "Stop"

# 1. Determine SD drive letters
$targetDrives = @()
if ($DriveLetter -ne "") {
    $targetDrives += $DriveLetter.Substring(0, 1).ToUpper()
} else {
    $volumes = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and $_.DriveLetter -notin @('C') }
    foreach ($v in $volumes) {
        $ltr = $v.DriveLetter.ToString().ToUpper()
        if (Test-Path "$($ltr):\") {
            $targetDrives += $ltr
        }
    }
    if ($targetDrives.Count -eq 0) {
        foreach ($cand in @("D", "E", "F", "G")) {
            if (Test-Path "$($cand):\") {
                $targetDrives += $cand
            }
        }
    }
}

if ($targetDrives.Count -eq 0) {
    Write-Host "Could not find any SD card drive (D, E, F, G). Please check insertion or pass -DriveLetter D" -ForegroundColor Red
    exit 1
}

$localSdDir = "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD"
$localFwDir = "$localSdDir\firmware"
[System.IO.Directory]::CreateDirectory($localFwDir) | Out-Null

$bruceBin   = "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin"
$zhillyBin  = "C:\zhilly_build\build\xiaozhi.bin"

if (Test-Path "$localFwDir\flipper.bin") {
    Remove-Item -Path "$localFwDir\flipper.bin" -Force -ErrorAction SilentlyContinue
}
if (Test-Path $bruceBin) {
    Copy-Item -Path $bruceBin -Destination "$localFwDir\bruce.bin" -Force
}
if (Test-Path $zhillyBin) {
    Copy-Item -Path $zhillyBin -Destination "$localFwDir\zhilly.bin" -Force
}

foreach ($dl in $targetDrives) {
    $sdPath = "$($dl):\"
    Write-Host "`n==================================================================" -ForegroundColor Cyan
    Write-Host ">>> TARGET SD CARD DETECTED AT: $sdPath" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Cyan

    # 2. PURGE EVERY SINGLE FLIPPER FILE & FOLDER
    Write-Host "`n>>> [1/4] Eradicating all Flipper files and folders from $sdPath..." -ForegroundColor Yellow

    $flipperItems = @(
        "$($sdPath)firmware\flipper.bin",
        "$($sdPath)flipper.bin",
        "$($sdPath)flipper",
        "$($sdPath)furi",
        "$($sdPath).furi",
        "$($sdPath).fw_version",
        "$($sdPath)anywaves",
        "$($sdPath)dolphin",
        "$($sdPath)apps_data",
        "$($sdPath)badusb",
        "$($sdPath)subghz",
        "$($sdPath)nfc",
        "$($sdPath)infrared",
        "$($sdPath)ibutton",
        "$($sdPath)u2f",
        "$($sdPath)lfs"
    )

    foreach ($item in $flipperItems) {
        if (Test-Path $item) {
            Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [PURGED FLIPPER] $item" -ForegroundColor Red
        }
    }

    # 3. Create clean folders for Bruce and Zhilly
    Write-Host "`n>>> [2/4] Ensuring clean folders on SD card..." -ForegroundColor Cyan
    [System.IO.Directory]::CreateDirectory("$($sdPath)firmware") | Out-Null
    [System.IO.Directory]::CreateDirectory("$($sdPath)bruce") | Out-Null
    [System.IO.Directory]::CreateDirectory("$($sdPath)zhilly") | Out-Null

    # 4. Sync binaries
    Write-Host "`n>>> [3/4] Copying fresh Bruce & Zhilly binaries to $($sdPath)firmware\..." -ForegroundColor Cyan
    if (Test-Path "$localFwDir\bruce.bin") {
        Copy-Item -Path "$localFwDir\bruce.bin" -Destination "$($sdPath)firmware\bruce.bin" -Force
        Write-Host "  [OK] $($sdPath)firmware\bruce.bin synchronized" -ForegroundColor Green
    }

    if (Test-Path "$localFwDir\zhilly.bin") {
        Copy-Item -Path "$localFwDir\zhilly.bin" -Destination "$($sdPath)firmware\zhilly.bin" -Force
        Write-Host "  [OK] $($sdPath)firmware\zhilly.bin synchronized" -ForegroundColor Green
    }

    # 5. Sync configs
    Write-Host "`n>>> [4/4] Writing Bruce and Zhilly configurations..." -ForegroundColor Cyan
    if (Test-Path "$localSdDir\bruce.conf") {
        Copy-Item -Path "$localSdDir\bruce.conf" -Destination "$($sdPath)bruce.conf" -Force
        Copy-Item -Path "$localSdDir\bruce.conf" -Destination "$($sdPath)bruce\bruce.conf" -Force
        Write-Host "  [OK] $($sdPath)bruce.conf synchronized" -ForegroundColor Green
    }

    if (Test-Path "$localSdDir\zhilly\config.json") {
        Copy-Item -Path "$localSdDir\zhilly\config.json" -Destination "$($sdPath)zhilly\config.json" -Force
        Write-Host "  [OK] $($sdPath)zhilly\config.json synchronized" -ForegroundColor Green
    }

    $stateJson = '{"brightness":75,"rotation":0,"led_brightness":32}'
    [System.IO.File]::WriteAllText("$($sdPath)zhilly\state.json", $stateJson)
    Write-Host "  [OK] $($sdPath)zhilly\state.json synchronized" -ForegroundColor Green

    Write-Host "`n==================================================================" -ForegroundColor Green
    Write-Host " SD CARD ($sdPath) FULLY CLEANED & PURGED OF ALL FLIPPER FILES!" -ForegroundColor Green
    Write-Host " ONLY BRUCE AND ZHILLY AI REMAIN READY FOR USE!" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
}
