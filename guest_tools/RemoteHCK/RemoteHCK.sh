#!/usr/bin/bash

SCRIPTS_DIR=`dirname $0`

#Frequwntly changed
testDevice='PCI\VEN_XXXX&DEV_XXXX&SUBSYS_XXXXXXXX'  #Format: PCI\VEN_XXXX&DEV_XXXX&SUBSYS_XXXXXXXX
projectName='TEST-PROJ'
cl1Name='CL1-2012R2X64'
cl2Name='CL2-2012R2X64'

#Occasionally changed
controllerIP='10.0.1.212'
winPasswd='PUT_YOUR_PASSWORD_HERE'

#Rarely changed
SMBShareDir="${SCRIPTS_DIR}/../../SMB_SHARE"
SHARE_ON_HOST_ADDR='192.168.101.1'

#Don't change, unless REALLY needed!
autoHCKFile="${SCRIPTS_DIR}/../AutoHCK/AutoHCK.ps1"
credsFile='creds.dat'

usage_and_exit()
{
    echo "Usage: $1 [ setup | run | shutdown-studio ]"
    exit 1
}

if [ $# -eq 0 ]
then
    usage_and_exit $0
elif [ $1 == "setup" ]
then
    # Create Creds file.
    echo "Creating credentials file..."
    echo "username=Administrator" > "$credsFile"
    echo "password=$winPasswd" >> "$credsFile"
    echo "domain=WORKGROUP" >> "$credsFile"
    # Change names in scripts and send changed scripts to shared folder.
    echo "Changing settings in scripts and copying them to $SMBShareDir ..."
    # Writing AutoHCK script
    sed "s|CL1-REPLACE|$cl1Name|g" "$autoHCKFile" > "$SMBShareDir/${autoHCKFile##*/}"
    sed -i "s|CL2-REPLACE|$cl2Name|g" "$SMBShareDir/${autoHCKFile##*/}"
    sed -i "s|DEVICE-REPLACE|$(printf "%q" "$testDevice")|g" "$SMBShareDir/${autoHCKFile##*/}"
    sed -i "s|TEST-REPLACE|$projectName|g" "$SMBShareDir/${autoHCKFile##*/}"
    # Create batch file to run AutoHCK
    echo '@echo off' > "$SMBShareDir/RunAutoHCK.bat"
    echo 'pushd \\'"$SHARE_ON_HOST_ADDR"'\qemu' >> "$SMBShareDir/RunAutoHCK.bat"
    echo 'copy "\\'"$SHARE_ON_HOST_ADDR"'\qemu\'"${autoHCKFile##*/}"'" "C:\'"${autoHCKFile##*/}"'"' >> "$SMBShareDir/RunAutoHCK.bat"
    echo '%windir%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy RemoteSigned -file "C:\'"${autoHCKFile##*/}"'"' >> "$SMBShareDir/RunAutoHCK.bat"
    echo 'popd' >> "$SMBShareDir/RunAutoHCK.bat"
elif [ $1 == "run" ]
then
    echo "Running..."
    winexe -A "$credsFile" //"$controllerIP" '\\'"$SHARE_ON_HOST_ADDR"'\qemu\RunAutoHCK.bat'
elif [ $1 == "shutdown-studio" ]
then
    echo "Shutting down HCK-STUDIO..."
    winexe -A "$credsFile" //"$controllerIP" 'shutdown /t 0 /s /f'
else
    usage_and_exit $0
fi
