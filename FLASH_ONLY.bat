@echo off
setlocal enabledelayedexpansion
title Flash All 3 Firmwares (Bruce DEV + Flipper + Zhilly AI)

echo ======================================================================
echo  FLASHING 3-IN-1 FIRMWARE TO T-EMBED CC1101 PLUS
echo ======================================================================

set IDF_PYTHON=C:\Espressif\python_env\idf5.4_py3.11_env\Scripts\python.exe
if not exist "%IDF_PYTHON%" (
    set IDF_PYTHON=C:\Users\Abdullah\.espressif\python_env\idf5.4_py3.11_env\Scripts\python.exe
)
if not exist "%IDF_PYTHON%" (
    set IDF_PYTHON=python.exe
)

echo Python: %IDF_PYTHON%

:: Check SD card D:
if exist D:\ (
    echo Syncing clean configs to SD card D:...
    if not exist D:\firmware mkdir D:\firmware
    if not exist D:\zhilly mkdir D:\zhilly
    if not exist D:\bruce mkdir D:\bruce
    copy /y "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin" "D:\firmware\bruce.bin"
    copy /y "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin" "D:\firmware\flipper.bin"
    copy /y "C:\zhilly_build\build\xiaozhi.bin" "D:\firmware\zhilly.bin"
    copy /y "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\bruce.conf" "D:\bruce.conf"
    copy /y "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\bruce.conf" "D:\bruce\bruce.conf"
    copy /y "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\zhilly\config.json" "D:\zhilly\config.json"
    copy /y "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\FUNDAMENTALS_3_IN_1.txt" "D:\FUNDAMENTALS_3_IN_1.txt"
    echo SD card D: synced!
)

:: Find Port
set PORT=COM13
echo Flashing on %PORT%...

echo [1/2] Erasing stale LittleFS region (0xF90000)...
"%IDF_PYTHON%" -m esptool --chip esp32s3 -p %PORT% -b 921600 --before default_reset --after no_reset erase_region 0xF90000 0x60000

echo [2/2] Writing Flash (Bootloader + Partition + Bruce + Flipper + Zhilly + Assets)...
"%IDF_PYTHON%" -m esptool --chip esp32s3 -p %PORT% -b 921600 --before no_reset --after hard_reset write_flash --flash_mode dio --flash_freq 80m --flash_size 16MB ^
    0x0 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\bootloader\bootloader.bin" ^
    0x8000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\partition_table\partition-table.bin" ^
    0x10000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\ota_data_initial.bin" ^
    0x20000 "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin" ^
    0x4E0000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin" ^
    0x880000 "C:\zhilly_build\build\xiaozhi.bin" ^
    0xB90000 "C:\zhilly_build\build\expression_assets.bin"

if %ERRORLEVEL% equ 0 (
    echo ======================================================================
    echo  SUCCESS! ALL 3 FIRMWARES FLASHED!
    echo ======================================================================
) else (
    echo ======================================================================
    echo  FLASH FAILED! Please hold the BOOT button while plugging USB and retry.
    echo ======================================================================
)
pause
