@echo off
chcp 65001 >nul
title [STEP 1] SD CARD PURGE & SYNC (BRUCE + ZHILLY AI v2.0.4)
color 0E

echo ==============================================================================
echo   STEP 1: CLEAN & SYNC SD CARD FOR VERSION 2.0.4
echo   - Purges ALL Flipper files and folders (flipper.bin, furi, dolphin, etc.)
echo   - Prepares clean Bruce and Zhilly AI v2.0.4 files on the SD card
echo ==============================================================================
echo.

cd /d "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES"
powershell -ExecutionPolicy Bypass -File ".\sync_sd_card.ps1"

echo.
echo ==============================================================================
echo   STEP 1 FINISHED! You can now proceed to Step 2 (Flash Device).
echo ==============================================================================
pause
