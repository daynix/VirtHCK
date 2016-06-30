#!/usr/bin/bash

SCRIPTS_DIR=`dirname $0`

################## Settings ###################

#Frequently changed
cl1Name='CL1-2012R2X64'
cl2Name='CL2-2012R2X64'

#Occasionally changed
KitVersion='8.1'  # Important! Change if using a different version! (Supported: 8, 8.1, 10)
KitInstallDir='HCK_release' # Directory where the kit installation files are on the SMB share
winPasswd='Adm1nPa$$word'
SMBShareDir="${SCRIPTS_DIR}/../../SMB_SHARE"

#External URL's (change if they have changed)
filtersURL="https://sysdev.microsoft.com/member/SubmissionWizard/LegalExemptions/HCKFilterUpdates.cab"
BginfoURL="https://download.sysinternals.com/files/BGInfo.zip"

#Rarely changed
SHARE_ON_HOST_ADDR='192.168.101.1'

#Don't change, unless REALLY needed!
sysSetupFile="${SCRIPTS_DIR}/SYS_SETUP.bat"
ControllerInstFile="${SCRIPTS_DIR}/CONTROLLER_INSTALL.bat"
ClientInstFile="${SCRIPTS_DIR}/CLIENT_INSTALL.bat"
bgiFile="${SCRIPTS_DIR}/bg_display_data.bgi"

############### End of settings ###############
###############################################

# Naming issues
WORD=$(echo | awk -v V="$KitVersion" '{if (V < 10) printf ("Certification"); else printf ("Lab");}')
LETTER=$(echo $WORD | head -c 1)
if [ $LETTER == "C" ]
then
    SUFFIX="exe"
elif [ $LETTER == "L" ]
then
    SUFFIX="cmd"
fi

if [ ! -f "$SMBShareDir/Bginfo.exe" ]
then
    mkdir "$SMBShareDir/BGInfo_tmp"
    curl -o "$SMBShareDir/BGInfo_tmp/BGInfo.zip" -L "$BginfoURL"
    unzip "$SMBShareDir/BGInfo_tmp/BGInfo.zip" -d "$SMBShareDir/BGInfo_tmp"
    mv "$SMBShareDir/BGInfo_tmp/Bginfo.exe" "$SMBShareDir"
    rm -rf "$SMBShareDir/BGInfo_tmp"
fi

echo "Changing settings in setup scripts and copying them to $SMBShareDir ..."
# Writing setup file to share
sed "s|PASSWORD-REPLACE|$winPasswd|g" "$sysSetupFile" > "$SMBShareDir/${sysSetupFile##*/}"
sed -i "s|BGI-REPLACE|${bgiFile##*/}|g" "$SMBShareDir/${sysSetupFile##*/}"
sed -i "s|REPLACE-SMB-ADDRESS|$SHARE_ON_HOST_ADDR|g" "$SMBShareDir/${sysSetupFile##*/}"
sed -i "s|CL1-REPLACE|$cl1Name|g"  "$SMBShareDir/${sysSetupFile##*/}"
sed -i "s|CL2-REPLACE|$cl2Name|g" "$SMBShareDir/${sysSetupFile##*/}"
sed -i "s|REPLACE-CONTROLLER-INST-FILE|${ControllerInstFile##*/}|g" "$SMBShareDir/${sysSetupFile##*/}"
sed -i "s|REPLACE-CLIENT-INST-FILE|${ClientInstFile##*/}|g" "$SMBShareDir/${sysSetupFile##*/}"
sed -i "s|REPLACE-LETTER|$LETTER|g" "$SMBShareDir/${sysSetupFile##*/}"
# Writing Controller install file to share
sed "s|REPLACE-SMB-ADDRESS|$SHARE_ON_HOST_ADDR|g" "$ControllerInstFile" > "$SMBShareDir/${ControllerInstFile##*/}"
sed -i "s|REPLACE-INSTALL-DIR|${KitInstallDir}|g" "$SMBShareDir/${ControllerInstFile##*/}"
sed -i "s|REPLACE-LETTER|$LETTER|g" "$SMBShareDir/${ControllerInstFile##*/}"
# Writing Client install file to share
sed "s|REPLACE-SMB-ADDRESS|$SHARE_ON_HOST_ADDR|g" "$ClientInstFile" > "$SMBShareDir/${ClientInstFile##*/}"
sed -i "s|REPLACE-LETTER|$LETTER|g" "$SMBShareDir/${ClientInstFile##*/}"
sed -i "s|REPLACE-SUFFIX|$SUFFIX|g" "$SMBShareDir/${ClientInstFile##*/}"
# Copying the BGI file to share
cp "$bgiFile" "$SMBShareDir/${bgiFile##*/}"
# Creating a run script for the studio
printf "start /D \"%%WTTSTDIO%%\\\\\" \"H%sK Studio\" \
\"%%WTTSTDIO%%\\h%skstudio.exe\"\r\n" "$LETTER" "${LETTER,,}"\
> "$SMBShareDir/RunStudio.bat"
# Creating an "Update Filters" script for the studio
printf "@echo off\r\n\
\r\n\
echo Updating H%sK Filters...\r\n\
echo Please make sure that all instances of the Studio are turned OFF!\r\n\
pause\r\n\
\r\n\
echo Downloading H%sK Filters...\r\n\
bitsadmin /transfer \"Downloading H%sK Filters\" \"%s\" \"C:\\H%sKFilterUpdates.cab\"\r\n\
if not errorlevel 0 echo ERROR & pause & exit /B 1\r\n\
\r\n\
echo Extracting...\r\n\
expand -i \"C:\\H%sKFilterUpdates.cab\" -f:UpdateFilters.sql \"%%DTMBIN%%\\\\\"\r\n\
if not errorlevel 0 echo ERROR & pause & exit /B 1\r\n\
\r\n\
echo Installing...\r\n\
pushd \"%%DTMBIN%%\\\\\"\r\n\
if not errorlevel 0 echo ERROR & pause & exit /B 1\r\n\
\"%%DTMBIN%%\\\\updatefilters.exe\"\r\n\
if not errorlevel 0 echo ERROR & pause & exit /B 1\r\npopd\r\n" \
$(printf "%0.s$LETTER " {1..3})"${filtersURL}" $(printf "%0.s$LETTER " {1..2})\
> "$SMBShareDir/UpdateFilters.bat"
# Placing a file in SMB_SHARE to make it available to clients
touch "$SMBShareDir/USE_SHARE"
