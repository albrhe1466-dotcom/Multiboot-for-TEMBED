@echo off
chcp 65001 >nul
title DUAL BOOT (BRUCE + ZHILLY AI v2.0.2) - FULL FLASH
color 0B

echo ==============================================================================
echo   FULL DUAL-BOOT REFLASH: BRUCE + ZHILLY AI v2.0.2
echo ==============================================================================
echo.

cd /d "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES"

echo [1/2] Syncing SD Card (Purging Flipper)...
powershell -ExecutionPolicy Bypass -File ".\sync_sd_card.ps1"
echo.

echo [2/2] Full Dual-Boot Build & Flash to COM13...
powershell -ExecutionPolicy Bypass -File ".\build_flash_fast.ps1"
echo.

echo ==============================================================================
echo   FULL DUAL-BOOT FLASH COMPLETE!
echo ==============================================================================
pause
