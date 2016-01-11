@echo off
echo Waiting 30 s to stabilize...
timeout /t 30 /nobreak > NUL
set instfile="\\REPLACE-SMB-ADDRESS\qemu\REPLACE-INSTALL-DIR\HREPLACE-LETTERKSetup.exe"
if not exist %instfile% (
    echo The installation file does not exist in the specified path:
    echo %instfile%
    echo Please install manually!
    pause & exit /B 1
)
echo Validating that SMB_SHARE is mapped to drive X: ...
if not exist x:\ (
    echo Was not mapped. Mapping...
    net use X: "\\REPLACE-SMB-ADDRESS\qemu" /P:Yes
) else (
    echo OK
)
echo Installing HREPLACE-LETTERK Controller and Studio. This will take a VERY long time!
echo SERIOUSLY! IT CAN TAKE OVER AN HOUR!
echo Grab yourself a meal!
echo Performing the installation - be VERY patient!
%instfile% /q
if not errorlevel 0 (
    echo Installation FAILED! Please install manually.
    pause & exit /B 1
) else (
    echo Installation FINISHED!
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "UpdateFilters" /t REG_SZ /d "C:\Users\Administrator\Desktop\UpdateFilters.bat" /f
)
echo Rebooting in 30s...
shutdown /t 30 /r /f
