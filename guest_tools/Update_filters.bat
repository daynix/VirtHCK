@echo off

:: Filter updater for HCK and HLK
:::::::::::::::::::::::::: Settings :::::::::::::::::::::::::::::::::
:: Notice: As of July 2015, the HCK and the HLK filter updates are the exact same file, downloaded from the same location!
SET "source=https://sysdev.microsoft.com/member/SubmissionWizard/LegalExemptions/HCKFilterUpdates.cab"

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

SET "destination=C:\FilterUpdates.cab"

if not exist "%DTMBIN%\" (
    echo ERROR: folder "%DTMBIN%"
    echo does not exist! Please verify that you have the controller installed.
    pause
    exit /B 1
)

echo Please make sure that all instances of the Studio are turned OFF!
pause

echo Downloading Filters...
bitsadmin /transfer "Downloading Filters" "%source%" "%destination%"
if not errorlevel 0 echo ERROR & pause & exit /B 1
echo Extracting...
expand -i "%destination%" -f:UpdateFilters.sql "%DTMBIN%\"
if not errorlevel 0 echo ERROR & pause & exit /B 1
echo Installing...
pushd "%DTMBIN%\"
if not errorlevel 0 echo ERROR & pause & exit /B 1
"%DTMBIN%\updatefilters.exe"
if not errorlevel 0 echo ERROR & pause & exit /B 1
popd
