@echo off

REM Obtain admin perms by creating a temporary VBS script that calls a UAC prompt
net session >nul 2>&1
if not %errorlevel% == 0 (
    echo Requesting administrative privileges...
    echo set UAC = CreateObject^("Shell.Application"^) > "%temp%\UAC.vbs"
    set "params=%*"
    echo UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\UAC.vbs"
    "%temp%\UAC.vbs"
    del "%temp%\UAC.vbs"
    exit /b
)

set "VANGUARD_DIR=%PROGRAMFILES%\Riot Vanguard"

REM Checks for valid directory
if not exist "%VANGUARD_DIR%" (
    echo Vanguard directory is invalid. It is either not at the default location or not installed.
    pause
    exit
) 

REM Changes working directory to Vanguard directory
pushd "%VANGUARD_DIR%"

REM Checks for conflicting versions of Vanguard, removes outdated version found
for %%a in ("installer.exe", "log-uploader.exe", "vgc.exe", "vgc.ico", "vgk.sys", "vgrl.dll", "vgtray.exe") do (
    if exist "%%a" (
        del "%%a.bak" >nul 2>&1
    )
)

:Toggle
if exist "vgk.sys" (
    REM Stops Vanguard services, renames key files, and deletes Vanguard logs
    echo Disabling Vanguard...
    sc config vgc start= disabled >nul 2>&1
    sc config vgk start= disabled >nul 2>&1
    net stop vgc >nul 2>&1
    net stop vgk >nul 2>&1
    taskkill /f /im vgtray.exe >nul 2>&1
    for %%a in (*) do (
        ren "%%a" "%%a.bak"
    )
    del /q "Logs"
) else (
    REM Reverts changes made by disable function and reinstates services, then restarts the system after 30 seconds w/ countdown
    echo Enabling Vanguard...
    for %%a in (*) do (
        ren "%%a" "%%~na"
    )
    sc config vgc start= demand
    sc config vgk start= system
    for /l %%b in (30 -1 1) do (
        cls
        echo Restarting in: %%b Seconds - [C]ancel / [R]estart Now
        for /f "delims=" %%c in ('Choice /T 1 /N /C:CSRW /D W') do (
            if %%c==C goto :Toggle
            if %%c==R shutdown /r /f /t 00
        )
    )
    shutdown /r /f /t 00
)

exit
