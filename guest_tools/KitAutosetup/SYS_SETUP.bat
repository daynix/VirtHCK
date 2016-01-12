@echo off
setlocal EnableDelayedExpansion
echo Waiting 30 s to stabilize...

timeout /t 30 /nobreak > NUL

echo Disabling Server Manager popup on startup...

reg add "HKLM\SOFTWARE\Microsoft\ServerManager" /v "DoNotOpenServerManagerAtLogon" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\ServerManager\Oobe" /v "DoNotOpenInitialConfigurationTasksAtLogon" /t REG_DWORD /d "1" /f

echo Mapping SMB_SHARE to drive X: ...

net use X: \\REPLACE-SMB-ADDRESS\qemu /P:Yes

echo Enabling Administrator account...

net user administrator /active:yes
net user administrator "PASSWORD-REPLACE"

echo Enabling auto-logon for Administrator...

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /t REG_SZ /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName" /t REG_SZ /d "WORKGROUP" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /t REG_SZ /d "Administrator" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /t REG_SZ /d "PASSWORD-REPLACE" /f

echo Disabling Windows Firewall...

netsh advfirewall set allprofiles state off
reg add "HKLM\SOFTWARE\Microsoft\Security Center" /v "FirewallDisableNotify" /t REG_DWORD /d "1" /f

echo Setting unidentified networks to Private Location...

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\010103000F0000F0010000000F0000F0C967A3643C3AD745950DA7859209176EF5B87C875FA20DF21951640E807D7C24" /v "Category" /t REG_DWORD /d "1" /f

echo Disabling Windows Update...

sc config wuauserv start= disabled
sc stop wuauserv
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "AUOptions" /t REG_DWORD /d "1" /f

echo Disabling screensaver...

reg add "HKCU\Control Panel\Desktop" /v "ScreenSaveActive" /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Desktop" /v "SCRNSAVE.EXE" /t REG_SZ /d "" /f

echo Disabling power saving options...

powercfg -change -monitor-timeout-ac 0
powercfg -change -disk-timeout-ac 0
powercfg -change -standby-timeout-ac 0
powercfg -hibernate off

echo Setting the informative wallpaper related material...

copy "\\REPLACE-SMB-ADDRESS\qemu\Bginfo.exe" "C:\"
copy "\\REPLACE-SMB-ADDRESS\qemu\BGI-REPLACE" "C:\"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "BgInfo" /t REG_SZ /d "C:\Bginfo.exe C:\BGI-REPLACE /TIMER:0 /NOLICPROMPT /SILENT" /f

for /f "delims=" %%a in ('getmac /fo csv /nh /v') do (
    set line=%%a
    set line=!line:"=,!
    for /f "delims=,,, tokens=1,3" %%b in ("!line!") do (
        set name=%%b
        set mac=%%c
        if "!mac:~-2!"=="DD" (
            netsh interface set interface name="!name!" newname="External"
        )
        if "!mac:~-2!"=="AA" (
            netsh interface set interface name="!name!" newname="ShareConnect"
        )
        if "!mac!"=="56-CC-CC-FF-CC-CC" (
            netsh interface ip set address name="!name!" static 192.168.100.1 255.255.255.0
            netsh interface set interface name="!name!" newname="Control"
            copy "\\REPLACE-SMB-ADDRESS\qemu\REPLACE-CONTROLLER-INST-FILE" "C:\"
            copy "\\REPLACE-SMB-ADDRESS\qemu\RunStudio.bat" "C:\Users\Administrator\Desktop\"
            copy "\\REPLACE-SMB-ADDRESS\qemu\UpdateFilters.bat" "C:\Users\Administrator\Desktop\"
            if %computername%==HREPLACE-LETTERK-STUDIO (
                "C:\REPLACE-CONTROLLER-INST-FILE"
            ) else (
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "HREPLACE-LETTERKinstall" /t REG_SZ /d "C:\REPLACE-CONTROLLER-INST-FILE" /f
                echo Will restart now...
                netdom renamecomputer %computername% /NewName:HREPLACE-LETTERK-STUDIO /UserD:Administrator /PasswordD:"PASSWORD-REPLACE" /Force /REBoot:20
            )
        )
        if "!mac!"=="56-CC-CC-01-CC-CC" (
            netsh interface ip set address name="!name!" static 192.168.100.2 255.255.255.0
            netsh interface set interface name="!name!" newname="MessageDevice"
            copy "\\REPLACE-SMB-ADDRESS\qemu\REPLACE-CLIENT-INST-FILE" "C:\"
            if %computername%==CL1-REPLACE (
                "C:\REPLACE-CLIENT-INST-FILE"
            ) else (
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "HREPLACE-LETTERKinstall" /t REG_SZ /d "C:\REPLACE-CLIENT-INST-FILE" /f
                echo Will restart now...
                netdom renamecomputer %computername% /NewName:"CL1-REPLACE" /UserD:Administrator /PasswordD:"PASSWORD-REPLACE" /Force /REBoot:20
            )
        )
        if "!mac!"=="56-CC-CC-02-CC-CC" (
            netsh interface ip set address name="!name!" static 192.168.100.3 255.255.255.0
            netsh interface set interface name="!name!" newname="MessageDevice"
            copy "\\REPLACE-SMB-ADDRESS\qemu\REPLACE-CLIENT-INST-FILE" "C:\"
            if %computername%==CL2-REPLACE (
                "C:\REPLACE-CLIENT-INST-FILE"
            ) else (
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "HREPLACE-LETTERKinstall" /t REG_SZ /d "C:\REPLACE-CLIENT-INST-FILE" /f
                echo Will restart now...
                netdom renamecomputer %computername% /NewName:"CL2-REPLACE" /UserD:Administrator /PasswordD:"PASSWORD-REPLACE" /Force /REBoot:20
            )
        )
    )
)
