@echo off
echo Waiting 30 s to stabilize...
timeout /t 30 /nobreak > NUL
set instfile="\\HREPLACE-LETTERK-STUDIO\HREPLACE-LETTERKInstall\Client\setup.REPLACE-SUFFIX"
if not exist %instfile% (
    echo The installation file does not exist in the specified path:
    echo %instfile%
    echo ^(Is the controller VM accessible?^) Please install manually!
    pause & exit /B 1
)
echo The SMB share won't be avaliable on this machine after a shutdown cycle.
echo If needed, it can be activated again by placing a file named "USE_SHARE" there and restarting via a shutdown.
del "\\REPLACE-SMB-ADDRESS\qemu\USE_SHARE"
echo Still, validating that SMB_SHARE is mapped to drive X: ...
echo ^(That may be needed if SMB_SHARE will be re-enabled^)
if not exist x:\ (
    echo Was not mapped. Mapping...
    net use X: "\\REPLACE-SMB-ADDRESS\qemu" /P:Yes
) else (
    echo OK
)
echo Installing the HREPLACE-LETTERK Client. This will take a VERY long time!
echo SERIOUSLY! IT WILL BE LONG!
echo Grab yourself a meal!
echo Performing the installation - be VERY patient!
cmd /C %instfile% /qn ICFAGREE=Yes
if not errorlevel 0 (
    echo Installation FAILED! Please install manually.
    pause & exit /B 1
) else (
    echo Installation FINISHED!
)
echo Rebooting in 30s...
shutdown /t 30 /r /f
