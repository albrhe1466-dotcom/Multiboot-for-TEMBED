@echo off
chcp 65001 >nul
title [v1.0.9] BUILD FLIPPER ZERO ESP32 FIRMWARE
color 0B

echo ==============================================================================
echo    LILYGO T-EMBED CC1101 PLUS - BUILD FLIPPER ZERO v1.0.9
echo ==============================================================================
echo    Compiling Flipper Zero ESP32 Port with:
echo      - Animated Zhilly Glitch-Tear Eyes icon (14x14)
echo      - Animated Bruce Shark Chomp icon (14x14)
echo      - Menu switches placed right between NFC and Infrared
echo ==============================================================================
echo.

set "IDF_PATH=C:\Espressif\frameworks\esp-idf-v5.4.1"
set "IDF_TOOLS_PATH=C:\Espressif"
set "ESP_ROM_ELF_DIR=C:\Espressif\frameworks\esp-idf-v5.4.1"

if exist "%IDF_PATH%\export.bat" (
    echo [INFO] Loading ESP-IDF environment...
    call "%IDF_PATH%\export.bat" >nul 2>&1
)

cd /d "c:\Users\Abdullah\Desktop\qias\flipper_src\build"

set "NINJA_EXE="
if exist "C:\Espressif\tools\ninja\1.12.1\ninja.exe" set "NINJA_EXE=C:\Espressif\tools\ninja\1.12.1\ninja.exe"
if "%NINJA_EXE%"=="" if exist "C:\Espressif\tools\ninja\1.11.1\ninja.exe" set "NINJA_EXE=C:\Espressif\tools\ninja\1.11.1\ninja.exe"
if "%NINJA_EXE%"=="" if exist "C:\Espressif\tools\ninja\1.10.2\ninja.exe" set "NINJA_EXE=C:\Espressif\tools\ninja\1.10.2\ninja.exe"
if "%NINJA_EXE%"=="" (
    for /f "tokens=*" %%i in ('where ninja 2^>nul') do set "NINJA_EXE=%%i"
)

if not "%NINJA_EXE%"=="" (
    echo [INFO] Running Ninja build (target: app)...
    "%NINJA_EXE%" app
) else (
    echo [INFO] Running idf.py build...
    idf.py build
)

if exist "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin" (
    echo.
    echo [INFO] Copying furi_esp32.bin -> 3 FRIMWARES\bin\flipper.bin...
    copy /y "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin" "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\bin\flipper.bin" >nul
    echo.
    echo ==============================================================================
    echo  [SUCCESS] FLIPPER ZERO v1.0.9 COMPILED AND SYNCED TO bin\flipper.bin!
    echo ==============================================================================
) else (
    echo.
    echo [ERROR] Build failed or furi_esp32.bin not produced.
)

pause
