@echo off
SET SDK_PATH=C:\Users\shrey\AppData\Local\Android\Sdk
SET AVD_NAME=MyEmulator

echo Starting Android Emulator...
start "" %SDK_PATH%\emulator\emulator -avd %AVD_NAME% -no-snapshot-load

echo Waiting for Emulator to Boot...
ping -n 10 127.0.0.1 >nul

:: Ask for APK path
set /p APK_PATH=Enter full path to APK: 
set "APK_PATH=%APK_PATH:"=%"

echo Installing APK...
%SDK_PATH%\platform-tools\adb install -r "%APK_PATH%"

echo Done! Your App is Installed. Enjoy!
pause
