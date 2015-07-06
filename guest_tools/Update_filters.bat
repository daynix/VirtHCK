@echo off

:::::::::::::::::::::::::: Settings :::::::::::::::::::::::::::::::::

:: Notice: As of July 2015, the HCK and the HLK filter updates are the exact same file, downloaded from the same location!
SET "source=https://sysdev.microsoft.com/member/SubmissionWizard/LegalExemptions/HCKFilterUpdates.cab"
:: version: 8 or 8.X for HCK, 10 or 10.X for HLK.
SET version=10

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

SET midword=None

if %version:~0,1%==8 (
    SET midword=Certification
)
if %version:~0,2%==10 (
    SET midword=Lab
)
if %midword%==None (
    echo ERROR: only HCK and HLK ^(versions 8, 8.X, 10, 10.X^) are supported.
    pause
    exit /B 1
)

SET midletter=%midword:~0,1%
SET "destination=C:\H%midletter%KFilterUpdates.cab"
SET "KitDir=C:\Program Files (x86)\Windows Kits\%version%"

if not exist "%KitDir%" (
    echo ERROR: folder "%KitDir%"
    echo does not exist! Please check that you specified the correct version.
    pause
    exit /B 1
)

echo Please make sure that all instances of the Studio are turned OFF!
pause

echo Downloading H%midletter%K Filters...
bitsadmin /transfer "Downloading H%midletter%K Filters" "%source%" "%destination%"
if not errorlevel 0 echo ERROR & pause & exit /B 1
echo Extracting...
expand -i "%destination%" -f:UpdateFilters.sql "%KitDir%\Hardware %midword% Kit\Controller"
if not errorlevel 0 echo ERROR & pause & exit /B 1
echo Installing...
pushd "%KitDir%\Hardware %midword% Kit\Controller"
if not errorlevel 0 echo ERROR & pause & exit /B 1
"%KitDir%\Hardware %midword% Kit\Controller\updatefilters.exe"
if not errorlevel 0 echo ERROR & pause & exit /B 1
popd
