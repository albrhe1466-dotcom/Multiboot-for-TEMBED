@echo off
chcp 65001 >nul
title Building Zhilly AI Firmware for Web Flasher
color 0B

echo ==============================================================================
echo   RECOMPILING ZHILLY AI (NO BUZZ + SUBTITLES ON SCREEN + ARABIC/TURKISH/EN)
echo ==============================================================================
echo.

set "IDF_PATH=C:\Espressif\frameworks\esp-idf-v5.5.5"
set "PY_EXE=C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
set "ESP_ROM_ELF_DIR=C:\Espressif\tools\esp-rom-elfs\20241011"

:: Set up IDF environment tools path
set "PATH=C:\Espressif\python_env\idf5.5_py3.11_env\Scripts;C:\Espressif\tools\ninja\1.12.1;C:\Espressif\tools\cmake\3.30.2\bin;C:\Espressif\tools\xtensa-esp-elf\esp-14.2.0_20241119\xtensa-esp-elf\bin;C:\Espressif\tools\ccache\4.10.2;%PATH%"

cd /d "C:\zhilly_build"
echo Building xiaozhi.bin with ninja...
"%PY_EXE%" "%IDF_PATH%\tools\idf.py" build

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed! Check compiler logs above.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [OK] Compilation successful!
echo Copying updated xiaozhi.bin to Web Flasher bin folder...
copy /y "C:\zhilly_build\build\xiaozhi.bin" "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\bin\zhilly.bin"
if exist "C:\zhilly_build\build\expression_assets.bin" (
    copy /y "C:\zhilly_build\build\expression_assets.bin" "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\bin\expression_assets.bin"
)

echo.
echo ==============================================================================
echo   ZHILLY AI FIRMWARE UPDATED IN WEB FLASHER (bin\zhilly.bin)!
echo   Now click "اتصال وفلاش الجهاز" in your browser flasher!
echo ==============================================================================
echo.
pause
