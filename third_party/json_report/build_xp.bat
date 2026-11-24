@echo off
if not defined MSYS2 set "MSYS2=C:\msys64"
set PATH=%MSYS2%\mingw32\bin;%PATH%
cd /d "%~dp0"

echo === Building json_report.exe (MinGW i686, static, XP-compatible) ===
windres.exe -O coff json_report.rc json_report_res.o
if errorlevel 1 goto :wfail
gcc.exe -O2 -Wall -D_WIN32_WINNT=0x0501 -DWINVER=0x0501 -municode -static -s -Xlinker --subsystem=console:5.1 -o json_report.exe json_report.c json_report_res.o -lshell32
if errorlevel 1 goto :gfail

echo === BUILD SUCCESSFUL ===
copy /Y "json_report.exe" "..\..\json_report.exe" >nul
if exist "..\..\Build" copy /Y "json_report.exe" "..\..\Build\json_report.exe" >nul
echo Installed to: ..\..\json_report.exe
dir json_report.exe
exit /b 0

:wfail
echo === BUILD FAILED - windres ===
exit /b 1

:gfail
echo === BUILD FAILED - gcc ===
exit /b 1
