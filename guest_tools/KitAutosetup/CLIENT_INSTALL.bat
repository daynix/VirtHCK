@echo off
echo Installing the HREPLACE-LETTERK Client. This will take a VERY long time!
echo SERIOUSLY! IT WILL BE LONG!
echo Grab yourself a meal!
echo Waiting 30s...
timeout /t 30 /nobreak > NUL
echo Performing the installation - be VERY patient!
cmd /C "\\HREPLACE-LETTERK-STUDIO\HREPLACE-LETTERKInstall\Client\setup.REPLACE-SUFFIX /qn ICFAGREE=Yes"

if not errorlevel 0 (
    echo Installation FAILED! Please install manually. & pause
) else (
    echo Installation SUCEEDED!
)

echo The SMB share won't be avaliable on this machine after a shutdown cycle.
echo If needed, it can be activated again by placing a file named "USE_SHARE" there and restarting via a shutdown.

del "\\REPLACE-SMB-ADDRESS\qemu\USE_SHARE"

echo ------
echo Still, validating that SMB_SHARE is mapped to drive X:
echo that may be needed if SMB_SHARE will be re-enabled...

if not exist x:\ (
    echo Was not mapped. Mapping...
    net use X: \\REPLACE-SMB-ADDRESS\qemu /P:Yes
) else (
    echo OK
)
echo ------

echo Press ENTER to reboot the system...
pause > NUL
shutdown /t 10 /r /f
