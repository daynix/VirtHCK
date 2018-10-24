::
:: Copyright (c) 2018, Daynix Computing LTD (www.daynix.com)
:: All rights reserved.
::
:: Maintained by oss@daynix.com
::
:: This file is a part of VirtHCK, please see the wiki page
:: on https://github.com/daynix/VirtHCK/wiki for more.
::
:: This code is licensed under standard 3-clause BSD license.
:: See file LICENSE supplied with this package for the full license text.
::
:: This batch file shall make clean up after WLK (Win8.1) RSC test
:: which almost always leaves its helper drivers (filter | protocol)
:: not completely uninstalled after the test; this causes next run of
:: the same test to fail due to error when installing filter/protocol
:: Restart after clean up before next test is very recommended.
::
@echo off
net session > nul
if errorlevel 1 goto noadmin
for /f "tokens=4 usebackq" %%a in (`pnputil -e ^| findstr /i .inf`) do call :one_inf %%a
timeout 20
exit /b 0

:one_inf
echo checking %windir%\inf\%1
call :check %1 coalesce.sys
call :check %1 spartadrv.sys
call :check %1 netcapdrv6.sys
goto :eof

:check
type %windir%\inf\%1 | findstr /i /c:%2
if not "%errorlevel%"=="0" goto :eof
echo uninstalling %1
pnputil /d %1
if "%errorlevel%"=="0" goto :delfile
echo force uninstall of %1
pnputil /f /d %1
:delfile
echo deleting %2
del %windir%\system32\drivers\%2
goto :eof

:noadmin
echo Run this batch as an administrator!
timeout 20
exit /b 1
