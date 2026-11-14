@echo off
chcp 65001 >nul
title ZHILLY AI v2.0.2 - BUILD & FLASH
color 0A

echo ==============================================================================
echo   ZHILLY AI v2.0.2 - CLEAN DUAL-BOOT (BRUCE + ZHILLY AI)
echo   * FIRST-BOOT LANGUAGE SELECTOR (ARABIC / TURKISH / ENGLISH)
echo   * BILLBOARD MARQUEE SCROLLING TICKER
echo   * 100%% ZERO MAC DISPLAY - 6-DIGIT PIN SPOKEN ALOUD
echo   * SD CARD FLIPPER PURGE
echo ==============================================================================
echo.

cd /d "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES"

echo [1/3] Syncing SD Card (Purging Flipper, keeping Bruce and Zhilly AI)...
powershell -ExecutionPolicy Bypass -File ".\sync_sd_card.ps1"
echo.

echo [2/3] Compiling and Flashing Zhilly AI v2.0.2 to COM13...
powershell -ExecutionPolicy Bypass -File ".\build_zhilly_fast.ps1"
echo.

echo ==============================================================================
echo   ZHILLY AI v2.0.2 FLASH COMPLETED SUCCESSFULLY!
echo ==============================================================================
pause
