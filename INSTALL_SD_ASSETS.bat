@echo off
title 3-in-1 Multi-Boot SD Card & Flipper Setup
color 0A
echo ========================================================
echo    LILYGO T-EMBED CC1101 PLUS - AUTOMATIC SD SETUP
echo ========================================================
echo.

set SDCARD=D:
if not exist %SDCARD%\ (
    echo [ERROR] SD Card not detected on D:!
    echo Please make sure your SD card is inserted.
    pause
    exit /b
)

echo [1/3] Found SD card at %SDCARD%\
echo.

echo [2/3] Downloading official Flipper Zero assets (sdcard.zip)...
curl -L -o "%TEMP%\sdcard.zip" "https://github.com/Sor3nt/Flipper-Zero-ESP32-Port/releases/download/v2.0.0/sdcard.zip"

if not exist "%TEMP%\sdcard.zip" (
    echo [ERROR] Download failed. Please check internet connection.
    pause
    exit /b
)

echo.
echo [3/3] Extracting assets directly to SD Card (%SDCARD%\)...
tar -xf "%TEMP%\sdcard.zip" -C "%SDCARD%\"
del "%TEMP%\sdcard.zip"

echo.
echo ========================================================
echo [SUCCESS] SD CARD IS FULLY POPULATED AND READY!
echo.
echo You can now insert the SD card into your LilyGO T-Embed.
echo Turn it on, and the Flipper Zero UI will appear instantly!
echo ========================================================
echo.
pause

