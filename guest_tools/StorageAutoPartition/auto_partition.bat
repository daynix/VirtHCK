@echo off
cd /d %~dp0
set Disk=%1
if "%Disk%"=="" set /p Disk=Please enter disk number:
call :generateScript
diskpart /s script
pause
goto :eof

:generateScript
  if "%Disk%"=="" goto :eof
  @echo sel disk %Disk% > script
  @echo create partition extended >> script
  @echo create partition logical size=2048 >> script
  @echo assign letter=g >> script
  @echo format fs=ntfs label=NTFS quick >> script
  @echo create partition logical size=2048 >> script
  @echo assign letter=i >> script
  @echo format fs=ntfs label=CNTFS compress quick >> script
  @echo create partition logical size=1024 >> script
  @echo assign letter=k >> script
  @echo format fs=fat label=FAT quick >> script
  @echo create partition logical size=1024 >> script
  @echo assign letter=l >> script
  @echo format fs=fat32 label=FAT32 quick >> script
  @echo create partition logical size=2048 >> script
  @echo assign letter=m >> script
  @echo format fs=exfat label=ExFAT quick >> script
  @echo create partition logical size=2048 >> script
  @echo assign letter=n >> script
  @echo format fs=udf label=UDF quick >> script
  @echo create partition logical size=10240 >> script
  @echo assign letter=o >> script
  @echo format fs=refs label=REFS quick >> script
goto :eof
