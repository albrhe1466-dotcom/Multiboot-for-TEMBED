@echo off
chcp 65001 >nul
title [STEP 2] BUILD ^& FLASH BRUCE + ZHILLY AI v1.0.9 (COM13)
color 0A

echo ==============================================================================
echo   STEP 2: COMPILE ^& FLASH BRUCE + ZHILLY AI v1.0.9 TO COM13
echo   - STARTS WITH BRUCE (ota_0)
echo   - Switch between them by rotating knob, Reboot menu, or pressing Top Button!
echo   - Language Selector (English / Arabic / Turkish)
echo   - Moving Marquee Billboard Ticker
echo   - Fresh 6-Digit PIN Audio & Display (No MAC)
echo ==============================================================================
echo.

cd /d "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES"
powershell -ExecutionPolicy Bypass -File ".\build_zhilly_fast.ps1"

echo.
echo ==============================================================================
echo   DUAL-BOOT FLASH COMPLETE! BOOTING INTO BRUCE!
echo ==============================================================================
pause
