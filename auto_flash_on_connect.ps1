$idfPython = "C:\Espressif\python_env\idf5.4_py3.11_env\Scripts\python.exe"
if (-not (Test-Path $idfPython)) {
    $idfPython = "C:\Users\Abdullah\.espressif\python_env\idf5.4_py3.11_env\Scripts\python.exe"
}
if (-not (Test-Path $idfPython)) {
    $idfPython = "python.exe"
}

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " AUTO-FLASH LISTENER ACTIVE: WAITING FOR ESP32-S3 ON COM PORT... " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Please plug in the device while holding the BOOT / Wheel button." -ForegroundColor Yellow
Write-Host "Flashing will trigger IMMEDIATELY the instant the port appears." -ForegroundColor Yellow

$portFound = $null
$deadline = (Get-Date).AddMinutes(3)

while ((Get-Date) -lt $deadline) {
    # Check CIM SerialPorts
    $ports = Get-CimInstance Win32_SerialPort -ErrorAction SilentlyContinue | Where-Object {
        $_.PNPDeviceID -match "VID_303A" -or $_.DeviceID -match "COM13|COM\d+"
    }
    if ($ports) {
        $portFound = $ports[0].DeviceID
        Write-Host "Found ESP32 port: $portFound!" -ForegroundColor Green
        break
    }
    Start-Sleep -Milliseconds 500
}

if (-not $portFound) {
    Write-Host "Timeout waiting for device port." -ForegroundColor Red
    exit 1
}

Write-Host "Starting flash on $portFound..." -ForegroundColor Green

# 1. Erase stale LittleFS
& $idfPython -m esptool --chip esp32s3 -p $portFound -b 921600 --before default_reset --after no_reset erase_region 0xF90000 0x60000

# 2. Write Flash
& $idfPython -m esptool --chip esp32s3 -p $portFound -b 921600 --before no_reset --after hard_reset write_flash --flash_mode dio --flash_freq 80m --flash_size 16MB `
    0x0 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\bootloader\bootloader.bin" `
    0x8000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\partition_table\partition-table.bin" `
    0x10000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\ota_data_initial.bin" `
    0x20000 "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin" `
    0x4E0000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin" `
    0x880000 "C:\zhilly_build\build\xiaozhi.bin" `
    0xB90000 "C:\zhilly_build\build\expression_assets.bin"

if ($LASTEXITCODE -eq 0) {
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host " SUCCESS! ALL 3 FIRMWARES FLASHED TO $portFound!" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
} else {
    Write-Host "Flashing failed with exit code $LASTEXITCODE" -ForegroundColor Red
}
