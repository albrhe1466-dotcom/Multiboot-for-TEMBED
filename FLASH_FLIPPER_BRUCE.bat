@echo off
chcp 65001 >nul
title [v1.0.9] FLASH FLIPPER ZERO + BRUCE (DUAL-BOOT)
color 0B

echo ==============================================================================
echo    LILYGO T-EMBED CC1101 PLUS - FLIPPER ZERO + BRUCE v1.0.9
echo ==============================================================================
echo    1. Flipper Zero ESP32 Port         -> 0x020000 (ota_0, 4.75 MB) [PRIMARY BOOT]
echo    2. Bruce RF Firmware               -> 0x4E0000 (ota_1, 4.69 MB)
echo.
echo    [HOW TO SWITCH FIRMWARE]
echo    - In Flipper Zero: Press Center OK knob to open Main Menu -> "Switch to Bruce"!
echo      (Features Animated Bruce Shark Chomp icon between NFC and Infrared)
echo    - In Bruce: Menu -> Reboot -> Switch OTA
echo ==============================================================================
echo.

cd /d "%~dp0"

:: Sync freshly built flipper binary if present
if exist "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin" (
    copy /y "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin" "bin\flipper.bin" >nul
)

:: Detect Python
set "PY_EXE="
if exist "C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe" (
    set "PY_EXE=C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
) else (
    where python >nul 2>&1
    if not errorlevel 1 set "PY_EXE=python"
)

if "%PY_EXE%"=="" (
    echo [ERROR] Python environment was not found.
    pause
    exit /b 1
)

:: Auto-detect COM port (default to COM13)
set "TARGET_PORT=COM13"
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'OK' -and ($_.InstanceId -like '*VID_303A*' -or $_.FriendlyName -like '*USB Serial*') } | Select-Object -First 1).FriendlyName"') do (
    for /f "tokens=2 delims=()" %%b in ("%%a") do set "TARGET_PORT=%%b"
)

echo [INFO] Target COM Port: %TARGET_PORT%
echo [INFO] Flashing Flipper Zero + Bruce Dual-Boot v1.0.9...
echo.

"%PY_EXE%" -m esptool --chip esp32s3 -p %TARGET_PORT% -b 921600 --before default_reset write_flash --flash_mode dio --flash_freq 80m --flash_size 16MB ^
    0x000000 "bin\bootloader.bin" ^
    0x008000 "bin\partition-table.bin" ^
    0x010000 "bin\ota_data_initial.bin" ^
    0x020000 "bin\flipper.bin" ^
    0x4E0000 "bin\bruce.bin" ^
    0x990000 "bin\blank_4k.bin"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Flashing failed! Check USB connection and hold BOOT button if needed.
    pause
    exit /b 1
)

echo.
echo ==============================================================================
echo  [SUCCESS] FLIPPER ZERO + BRUCE FLASHED SUCCESSFULLY (v1.0.9)!
echo  Primary OS: Flipper Zero will boot immediately!
echo ==============================================================================
"%PY_EXE%" -m esptool --chip esp32s3 -p %TARGET_PORT% --after hard_reset chip_id >nul 2>&1
pause
