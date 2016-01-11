#!/usr/bin/bash

SCRIPTS_DIR=`dirname $0`

################## Settings ###################

#Frequwntly changed
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
cat > "$SMBShareDir/RunStudio.bat" <<'EOF'
@echo off
echo Disabling the external network...
echo This may take a while - please be patient...

netsh interface set interface "External" DISABLE

echo Starting HREPLACE-LETTERK studio...

pushd "%WTTSTDIO%\"
"%WTTSTDIO%\hreplace-letterkstudio.exe"
popd

echo Enabling the external network...
netsh interface set interface "External" ENABLE
EOF
sed -i "s|REPLACE-LETTER|$LETTER|g" "$SMBShareDir/RunStudio.bat"
sed -i "s|replace-letter|${LETTER,,}|g" "$SMBShareDir/RunStudio.bat"
# Creating an "Update Filters" script for the studio
cat > "$SMBShareDir/UpdateFilters.bat" <<'EOF'
@echo off

echo Updating HREPLACE-LETTERK Filters...
echo Please make sure that all instances of the Studio are turned OFF!
pause

echo Downloading HREPLACE-LETTERK Filters...
bitsadmin /transfer "Downloading HREPLACE-LETTERK Filters" "REPLACE-FILTERS-URL" "C:\HREPLACE-LETTERKFilterUpdates.cab"
if not errorlevel 0 echo ERROR & pause & exit /B 1

echo Extracting...
expand -i "C:\HREPLACE-LETTERKFilterUpdates.cab" -f:UpdateFilters.sql "%DTMBIN%\"
if not errorlevel 0 echo ERROR & pause & exit /B 1

echo Installing...
pushd "%DTMBIN%\"
if not errorlevel 0 echo ERROR & pause & exit /B 1
"%DTMBIN%\updatefilters.exe"
if not errorlevel 0 echo ERROR & pause & exit /B 1
popd
EOF
sed -i "s|REPLACE-LETTER|$LETTER|g" "$SMBShareDir/UpdateFilters.bat"
sed -i "s|REPLACE-FILTERS-URL|${filtersURL}|g" "$SMBShareDir/UpdateFilters.bat"
# Placing a file in SMB_SHARE to make it available to clients
touch "$SMBShareDir/USE_SHARE"
