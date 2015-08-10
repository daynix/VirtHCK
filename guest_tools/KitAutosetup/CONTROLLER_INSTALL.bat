@echo off
echo Installing HREPLACE-LETTERK Controller and Studio. This will take a VERY long time!
echo SERIOUSLY! IT CAN TAKE OVER AN HOUR!
echo Grab yourself a meal!
echo Waiting 30s...
timeout /t 30 /nobreak > NUL
echo Performing the installation - be VERY patient!
"\\REPLACE-SMB-ADDRESS\qemu\REPLACE-INSTALL-DIR\HREPLACE-LETTERKSetup.exe" /q

if not errorlevel 0 (
    echo Installation FAILED! Please install manually. & pause
) else (
    echo Installation SUCEEDED!
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "UpdateFilters" /t REG_SZ /d "C:\Users\Administrator\Desktop\UpdateFilters.bat" /f
)

echo ------
echo Validating that SMB_SHARE is mapped to drive X: ...

if not exist x:\ (
    echo Was not mapped. Mapping...
    net use X: \\REPLACE-SMB-ADDRESS\qemu /P:Yes
) else (
    echo OK
)
echo ------

echo Rebooting in 30s...
shutdown /t 30 /r /f
