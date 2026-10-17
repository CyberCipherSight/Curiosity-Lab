@echo off
SET SDK_PATH=C:\Users\shrey\AppData\Local\Android\Sdk

echo Listing Available Emulators...
FOR /F "tokens=*" %%A IN ('%SDK_PATH%\emulator\emulator -list-avds') DO (
    echo %%A
)

echo.
echo Do you want to delete:
echo [1] A specific emulator
echo [2] All emulators
echo [3] Exit
set /p CHOICE="Enter your choice (1/2/3): "

if "%CHOICE%"=="1" goto DELETE_SPECIFIC
if "%CHOICE%"=="2" goto DELETE_ALL
if "%CHOICE%"=="3" exit

:DELETE_SPECIFIC
set /p AVD_NAME="Enter the emulator name to delete: "
%SDK_PATH%\cmdline-tools\latest\bin\avdmanager delete avd -n %AVD_NAME%
echo Emulator %AVD_NAME% deleted successfully!
pause
exit

:DELETE_ALL
FOR /F "tokens=*" %%A IN ('%SDK_PATH%\emulator\emulator -list-avds') DO (
    echo Deleting Emulator: %%A
    %SDK_PATH%\cmdline-tools\latest\bin\avdmanager delete avd -n %%A
)
echo Cleaning AVD Folder...
RMDIR /S /Q "%USERPROFILE%\.android\avd"

echo All Emulators Have Been Deleted!
pause
exit
