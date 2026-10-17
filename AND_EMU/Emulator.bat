@echo off
setlocal enabledelayedexpansion

:: ——— CONFIG ———
set "SDK_PATH=C:\Users\shrey\AppData\Local\Android\Sdk"
set "CMDLINE=%SDK_PATH%\cmdline-tools\latest\bin\avdmanager.bat"
set "EMULATOR=%SDK_PATH%\emulator\emulator.exe"
set "ADB=%SDK_PATH%\platform-tools\adb.exe"
set "SYS_IMG=system-images;android-32;google_apis_playstore;x86_64"
set "DEVICE=pixel_4"
:: ——————————————————

:: TOOL CHECKS
for %%T in ("%CMDLINE%" "%EMULATOR%" "%ADB%") do (
  if not exist %%~T (
    echo ERROR: File not found -> %%~T
    pause
    exit /b
  )
)

:TOP
cls
echo ============================================
echo      ANDROID AVD MANAGEMENT TOOL
echo ============================================
echo Current AVDs:
"%EMULATOR%" -list-avds | findstr /R "." || echo   [none installed]
echo ============================================
echo [1] Create new AVD
echo [2] Launch emulator
echo [3] Delete one AVD
echo [4] Delete all AVDs
echo [5] Exit
echo.
set /p MENU="Choose [1-5]: "

if "%MENU%"=="1" goto CREATE
if "%MENU%"=="2" goto LAUNCH
if "%MENU%"=="3" goto DELETE_ONE
if "%MENU%"=="4" goto DELETE_ALL
if "%MENU%"=="5" exit /b
goto TOP

:CREATE
echo.
set /p NEW_NAME="Enter new AVD name: "
if "%NEW_NAME%"=="" (
  echo Skipping creation.
  pause
  goto TOP
)
"%CMDLINE%" create avd -n "%NEW_NAME%" -k "%SYS_IMG%" --device "%DEVICE%"
if errorlevel 1 (
  echo ERROR: Could not create "%NEW_NAME%".
) else (
  echo Created AVD "%NEW_NAME%".
)
pause
goto TOP

:LAUNCH
echo.
set /p RUN_NAME="Enter AVD name to launch: "
if "%RUN_NAME%"=="" (
  echo Aborted.
  pause
  goto TOP
)
start "" "%EMULATOR%" -avd "%RUN_NAME%" -no-snapshot-load -netdelay none -netspeed full

echo.
echo Waiting for emulator "%RUN_NAME%" to boot...
"%ADB%" wait-for-device

:: confirm boot completion
set /a COUNT=0
:WAIT
"%ADB%" -s emulator-5554 shell getprop sys.boot_completed 2>nul | findstr 1 >nul
if errorlevel 1 (
  timeout /t 5 >nul
  set /a COUNT+=5
  if %COUNT% GEQ 120 (
    echo ERROR: Boot timeout.
    pause
    goto TOP
  )
  goto WAIT
)
echo Emulator "%RUN_NAME%" booted.

:: IMPROVED APK INSTALL
echo.
set /p APK_CHOICE="Install APK now? [Y/N]: "
if /I "%APK_CHOICE%"=="Y" (
  :APK_LOOP
  set /p APK_PATH="Enter full APK path (or type EXIT to cancel): "
  if /I "%APK_PATH%"=="EXIT" (
    echo Installation canceled.
    pause
    goto TOP
  )

  :: Remove any surrounding quotes (handles paths like "E:\path with space\app.apk")
  set "APK_PATH=%APK_PATH:"=%"

  if not exist "!APK_PATH!" (
    echo ERROR: File not found: "!APK_PATH!"
    echo Please try again or type EXIT.
    goto APK_LOOP
  )

  :: Find running emulator serial (assumes only one running)
  for /f "tokens=1" %%D in ('"%ADB%" devices ^| findstr emulator-') do set "SERIAL=%%D"

  echo Installing "!APK_PATH!" on !SERIAL!...
  "%ADB%" -s !SERIAL! install -r "!APK_PATH!"
  if errorlevel 1 (
    echo ERROR: APK install failed. Check compatibility or storage.
  ) else (
    echo APK installed successfully.
  )
  pause
)
goto TOP


:DELETE_ONE
echo.
echo Available AVDs:
"%EMULATOR%" -list-avds | findstr /R "." || (
  echo   [none installed]
  pause
  goto TOP
)
set /p DEL_NAME="Enter exact AVD name to delete: "
if "%DEL_NAME%"=="" goto TOP
"%CMDLINE%" delete avd -n "%DEL_NAME%" 2>nul
if errorlevel 1 (
  echo ERROR: Could not delete "%DEL_NAME%".
) else (
  echo Deleted "%DEL_NAME%".
)
pause
goto TOP

:DELETE_ALL
echo.
echo You are about to delete ALL AVDs.
set /p CONF="Type YES to confirm: "
if /I not "%CONF%"=="YES" (
  echo Aborted.
  pause
  goto TOP
)
for /f "delims=" %%A in ('"%EMULATOR%" -list-avds') do (
  echo Deleting %%A…
  "%CMDLINE%" delete avd -n "%%A" 2>nul
)
rmdir /s /q "%USERPROFILE%\.android\avd" 2>nul
echo All AVDs removed.
pause
goto TOP
