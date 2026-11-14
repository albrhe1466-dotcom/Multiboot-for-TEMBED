@echo off
chcp 65001 >nul
title [v2.0.5] FLASH ALL 3 FIRMWARES (BRUCE + FLIPPER + ZHILLY AI)
color 0A

echo ==============================================================================
echo    LILYGO T-EMBED CC1101 PLUS - MULTIBOOT v2.0.5 FLASH ENGINE
echo ==============================================================================
echo    1. Bruce RF Firmware               -> 0x020000 (ota_0, 4.75 MB)
echo    2. Flipper Zero ESP32 Port         -> 0x4E0000 (ota_1, 3.625 MB)
echo    3. Zhilly AI v2.0.5                -> 0x880000 (ota_2, 3.0 MB)
echo    4. Expression Assets (Oval Eyes)   -> 0xB90000 (4.0 MB)
echo.
echo    [SWITCHING CONTROLS]
echo    - In Flipper Zero: Rotate knob LEFT to open Lock Menu -> Switch to Bruce / Zhilly!
echo    - In Bruce: Menu -> Reboot -> Switch OTA
echo    - In Zhilly: Press side button to switch
echo ==============================================================================
echo.

cd /d "%~dp0"

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
echo [INFO] Writing full 16MB MultiBoot image (Bruce + Flipper + Zhilly AI v2.0.5)...
echo.

"%PY_EXE%" -m esptool --chip esp32s3 -p %TARGET_PORT% -b 921600 --before default_reset write_flash --flash_mode dio --flash_freq 80m --flash_size 16MB ^
    0x000000 "bin\bootloader.bin" ^
    0x008000 "bin\partition-table.bin" ^
    0x010000 "bin\ota_data_initial.bin" ^
    0x020000 "bin\bruce.bin" ^
    0x4E0000 "bin\flipper.bin" ^
    0x880000 "bin\zhilly.bin" ^
    0xB90000 "bin\expression_assets.bin"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Flashing failed! Check USB connection and hold BOOT button if needed.
    pause
    exit /b 1
)

echo.
echo ==============================================================================
echo  [SUCCESS] ALL 3 FIRMWARES FLASHED SUCCESSFULLY (v2.0.5)!
echo  Rebooting device...
echo ==============================================================================
"%PY_EXE%" -m esptool --chip esp32s3 -p %TARGET_PORT% --after hard_reset chip_id >nul 2>&1
pause
