@echo off
chcp 65001 >nul
title [v1.0.9] FLASH FLIPPER ZERO + ZHILLY AI (DUAL-BOOT)
color 0A

echo ==============================================================================
echo    LILYGO T-EMBED CC1101 PLUS - FLIPPER ZERO + ZHILLY AI v1.0.9
echo ==============================================================================
echo    1. Flipper Zero ESP32 Port         -> 0x020000 (ota_0, 4.75 MB) [PRIMARY BOOT]
echo    2. Zhilly AI v1.0.9                -> 0x990000 (ota_2, 3.0 MB)
echo    3. Expression Assets               -> 0xCA0000 (2.94 MB)
echo.
echo    [HOW TO SWITCH FIRMWARE]
echo    - In Flipper Zero: Press Center OK knob to open Main Menu -> "Switch to Zhilly AI"!
echo      (Located directly between NFC and Infrared with animated glitch-tear eyes)
echo    - In Zhilly AI: Press side button or click rotary knob to switch back!
echo.
echo    [ZHILLY AI FEATURES]
echo    - Arabic, Turkish, and English support ONLY (Chinese removed)
echo    - Glitch-free audio (16kHz direct I2S DMA for NS4168 Class-D amplifier)
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
echo [INFO] Flashing Flipper Zero + Zhilly AI Dual-Boot...
echo.

"%PY_EXE%" -m esptool --chip esp32s3 -p %TARGET_PORT% -b 921600 --before default_reset write_flash --flash_mode dio --flash_freq 80m --flash_size 16MB ^
    0x000000 "bin\bootloader.bin" ^
    0x008000 "bin\partition-table.bin" ^
    0x010000 "bin\ota_data_initial.bin" ^
    0x020000 "bin\flipper.bin" ^
    0x4E0000 "bin\blank_4k.bin" ^
    0x990000 "bin\zhilly_en.bin" ^
    0xCA0000 "bin\expression_assets.bin"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==============================================================================
    echo    [SUCCESS] Flipper Zero + Zhilly AI v1.0.9 FLASHED SUCCESSFULLY!
    echo    Primary OS: Flipper Zero will boot immediately!
    echo ==============================================================================
) else (
    echo.
    echo [ERROR] Flashing failed. Check USB connection and hold BOOT button while plugging in.
)

pause
