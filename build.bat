@echo off
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem Variant selection:
rem   build.bat        - build all three variants
rem   build.bat ra2    - build RA2MT    (Red Alert 2)
rem   build.bat yr     - build RA2YRMT  (Red Alert 2: Yuri's Revenge)
rem   build.bat mo     - build MOMT     (Mental Omega)
rem Each variant gets its own folder Build\<variant>\ with a self-contained
rem runtime: exe + settings.cfg + its own .enc set + DLL + helpers.
rem ---------------------------------------------------------------------------
set "DO_RA2=0"
set "DO_YR=0"
set "DO_MO=0"
if "%~1"=="" goto :all_variants
if /i "%~1"=="ra2" (set "DO_RA2=1" & goto :variants_ok)
if /i "%~1"=="yr" (set "DO_YR=1" & goto :variants_ok)
if /i "%~1"=="mo" (set "DO_MO=1" & goto :variants_ok)
echo ERROR: unknown variant "%~1" - use ra2, yr or mo
goto :done

:all_variants
set "DO_RA2=1"
set "DO_YR=1"
set "DO_MO=1"

:variants_ok

rem Check ResourceHacker
if not exist "tools\ResourceHacker.exe" (
    echo ResourceHacker.exe not found. Downloading from angusj.com...
    curl -L -o "tools\rh.zip" "https://www.angusj.com/resourcehacker/resource_hacker.zip" --progress-bar
    if exist "tools\rh.zip" (
        powershell -Command "Expand-Archive -Path 'tools\rh.zip' -DestinationPath 'tools\RH_tmp' -Force"
        powershell -Command "Move-Item 'tools\RH_tmp\ResourceHacker.exe' 'tools\ResourceHacker.exe' -Force"
        powershell -Command "Remove-Item 'tools\RH_tmp' -Recurse -Force; Remove-Item 'tools\rh.zip' -Force"
        echo ResourceHacker downloaded.
    ) else (
        echo ERROR: Download failed. Download manually from https://www.angusj.com/resourcehacker/
        goto :done
    )
)

rem Step 0: Build the starpack payload from a whitelist (one shared payload for
rem all variants). The vfs is deleted first, so nothing from an earlier build can
rem leak into the package (maintainer tools, stale modules). Only the files named
rem below are packaged; :verify_clean fails the build if a forbidden file is found.
set "VFS_APP=INI2MAP-Tester.vfs\lib\app-ini2map-tester"
echo Syncing INI2MAP-Tester.vfs...
if exist "INI2MAP-Tester.vfs" rmdir /S /Q "INI2MAP-Tester.vfs"
mkdir "INI2MAP-Tester.vfs"
rem Starpack bootstrap: the vfs root main.tcl loads the application from
rem lib/app-ini2map-tester. Written on every build so the package is
rem reproducible and the vfs can be wiped safely.
> "INI2MAP-Tester.vfs\main.tcl" (
    echo # INI2MAP-Tester bootstrap - source the real main.tcl from lib/app-ini2map-tester
    echo source [file join [file dirname [info script]] lib app-ini2map-tester main.tcl]
)
robocopy "aicheck" "INI2MAP-Tester.vfs\lib\app-ini2map-tester\aicheck" "*.tcl" /njh /njs /ndl /nc /ns /np >nul
if %ERRORLEVEL% GEQ 8 (echo ERROR: robocopy aicheck failed & goto :done)
robocopy "checks" "INI2MAP-Tester.vfs\lib\app-ini2map-tester\checks" "*.tcl" /njh /njs /ndl /nc /ns /np >nul
if %ERRORLEVEL% GEQ 8 (echo ERROR: robocopy checks failed & goto :done)
robocopy "map_parser" "INI2MAP-Tester.vfs\lib\app-ini2map-tester\map_parser" "*.tcl" /njh /njs /ndl /nc /ns /np >nul
if %ERRORLEVEL% GEQ 8 (echo ERROR: robocopy map_parser failed & goto :done)
robocopy "rules_parser" "INI2MAP-Tester.vfs\lib\app-ini2map-tester\rules_parser" "*.tcl" /njh /njs /ndl /nc /ns /np >nul
if %ERRORLEVEL% GEQ 8 (echo ERROR: robocopy rules_parser failed & goto :done)
robocopy "validators" "INI2MAP-Tester.vfs\lib\app-ini2map-tester\validators" "*.tcl" /njh /njs /ndl /nc /ns /np >nul
if %ERRORLEVEL% GEQ 8 (echo ERROR: robocopy validators failed & goto :done)
robocopy "taglist" "INI2MAP-Tester.vfs\lib\app-ini2map-tester\taglist" "*.tcl" /njh /njs /ndl /nc /ns /np >nul
if %ERRORLEVEL% GEQ 8 (echo ERROR: robocopy taglist failed & goto :done)
robocopy "others" "INI2MAP-Tester.vfs\lib\app-ini2map-tester\others" /E /PURGE /njh /njs /ndl /nc /ns /np >nul
if %ERRORLEVEL% GEQ 8 (echo ERROR: robocopy others failed & goto :done)
rem Root modules: runtime only. crypto_utils.tcl / check_key.tcl / encrypt_v2.tcl
rem are maintainer tooling and stay in the source tree, never in the payload.
set "ROOT_MODULES=main.tcl cli.tcl config.tcl constants.tcl data.tcl logging.tcl orchestrator.tcl validators.tcl checks.tcl map_parser.tcl rules_parser.tcl crypto.tcl audio_parser.tcl cache.tcl utils.tcl salt.tcl"
robocopy "." "%VFS_APP%" %ROOT_MODULES% /njh /njs /ndl /nc /ns /np >nul
if %ERRORLEVEL% GEQ 8 (echo ERROR: robocopy root .tcl files failed & goto :done)

rem Whitelist guard: every runtime module of the explicit list must be present,
rem and nothing forbidden may have slipped into the payload staging directory.
if not exist "INI2MAP-Tester.vfs\main.tcl" (echo BUILD FAILED: payload is missing the starpack bootstrap main.tcl & goto :done)
for %%f in (%ROOT_MODULES%) do (
    if not exist "%VFS_APP%\%%f" (echo BUILD FAILED: payload is missing %%f & goto :done)
)
call :verify_clean "INI2MAP-Tester.vfs"
if errorlevel 1 goto :done
echo INI2MAP-Tester.vfs synced.

rem Maintainer build only: the marker unlocks --salt / --show-salt inside the
rem payload. It is written into the vfs, so a recipient cannot add it later.
if defined INI2MAP_MAINTAINER (
    echo Maintainer build - ^--salt and ^--show-salt are enabled > "%VFS_APP%\maintainer.enabled"
    echo MAINTAINER BUILD: --salt and --show-salt are enabled in this payload.
)

rem Step 1: Locate tclkit (override with the TCLKIT env var if it lives elsewhere)
if not defined TCLKIT set "TCLKIT=C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe"
if not exist "%TCLKIT%" (
    echo ERROR: tclkit not found: %TCLKIT%
    echo        Set TCLKIT=path\to\base-tcl8.6-thread-win32-ix86.exe
    goto :done
)
copy /Y "%TCLKIT%" "tools\base.exe" >nul

rem Step 2: Wrap with sdx. The kit must be a different file than tools\base.exe:
rem base.exe is the output prefix, and a running exe is locked on Windows.
rem One wrap - all variants share the same INI2MAP-Tester.vfs payload, each variant gets
rem its own copy of the wrapped kit renamed to <VARIANT>.exe.
"%TCLKIT%" "tools\sdx.kit" wrap INI2MAP-Tester -runtime "tools\base.exe"
if not exist "INI2MAP-Tester" (
    echo BUILD FAILED: sdx wrap
    goto :done
)

rem Step 3-5: per-variant exe + icon + version resource + runtime files
if "%DO_RA2%"=="1" (
    call :build_variant ra2
    if errorlevel 1 goto :done
)
if "%DO_YR%"=="1" (
    call :build_variant yr
    if errorlevel 1 goto :done
)
if "%DO_MO%"=="1" (
    call :build_variant mo
    if errorlevel 1 goto :done
)
del "INI2MAP-Tester" 2>nul

rem Shared root files (HTML report: json_report mission.log)
copy /Y "others\ffidl\ffidl_xp.dll" "ffidl_xp.dll" >nul
copy /Y "third_party\json_report\json_report.exe" "json_report.exe" >nul

echo.
echo Done.
if "%DO_RA2%"=="1" echo   Build\RA2MT\RA2MT.exe
if "%DO_YR%"=="1" echo   Build\RA2YRMT\RA2YRMT.exe
if "%DO_MO%"=="1" echo   Build\MOMT\MOMT.exe
echo json_report.exe copied to project root (HTML report: json_report mission.log)
goto :eof

rem ---------------------------------------------------------------------------
rem :build_variant <ra2|yr|mo>
rem Copies the wrapped kit to Build\<variant>\<variant>.exe, injects its icon
rem and version resource, then copies the self-contained runtime next to it.
rem ---------------------------------------------------------------------------
:build_variant
set "V=%~1"
if "%V%"=="ra2" (
    set "OUTDIR=Build\RA2MT"
    set "EXE=RA2MT.exe"
    set "ICON=RA2MT.ico"
    set "VERRES=tools\version_ra2.res"
    set "SETTINGS=settings-ra2.cfg"
    set "SCOPE=ra2mt"
    set "ENCLIST=rules.enc ai.enc art.enc sound.enc theme.enc eva.enc audio_ra2.enc"
) else if "%V%"=="yr" (
    set "OUTDIR=Build\RA2YRMT"
    set "EXE=RA2YRMT.exe"
    set "ICON=RA2YRMT.ico"
    set "VERRES=tools\version_ra2yr.res"
    set "SETTINGS=settings-yr.cfg"
    set "SCOPE=ra2yrmt"
    set "ENCLIST=rulesmd.enc aimd.enc artmd.enc soundmd.enc thememd.enc evamd.enc audio_ra2.enc audio_yr.enc"
) else (
    set "OUTDIR=Build\MOMT"
    set "EXE=MOMT.exe"
    set "ICON=MOMT.ico"
    set "VERRES=tools\version.res"
    set "SETTINGS=settings.cfg"
    set "SCOPE=momt"
    set "ENCLIST=rulesmo.enc aimo.enc artmo.enc soundmo.enc thememo.enc evamo.enc audio.enc audio_ra2.enc audio_yr.enc"
)

echo.
echo Building %EXE%...

rem Every .enc of this variant must exist in the project root first
for %%f in (%ENCLIST%) do (
    if not exist "%%f" (
        echo BUILD FAILED: missing %%f ^(run crypto_utils.tcl --encrypt-originals^)
        exit /b 1
    )
)

if not exist "%OUTDIR%" mkdir "%OUTDIR%"
copy /Y "INI2MAP-Tester" "%OUTDIR%\%EXE%" >nul
if not exist "%OUTDIR%\%EXE%" (
    echo BUILD FAILED: cannot copy wrapped kit to %OUTDIR%\%EXE%
    exit /b 1
)

rem Step 4: Add icon and version resource via ResourceHacker
tools\ResourceHacker.exe -open "%OUTDIR%\%EXE%" -save "%OUTDIR%\%EXE%" -action delete -mask "ICONGROUP,," -log NUL
tools\ResourceHacker.exe -open "%OUTDIR%\%EXE%" -save "%OUTDIR%\%EXE%" -action delete -mask "VERSION,," -log NUL
tools\ResourceHacker.exe -open "%OUTDIR%\%EXE%" -save "%OUTDIR%\%EXE%" -action addoverwrite -resource "%ICON%" -mask "ICONGROUP,MAINICON," -log NUL
tools\ResourceHacker.exe -open "%OUTDIR%\%EXE%" -save "%OUTDIR%\%EXE%" -action addoverwrite -resource "%VERRES%" -mask "VERSION,," -log NUL
if not exist "%OUTDIR%\%EXE%" (
    echo BUILD FAILED: ResourceHacker on %OUTDIR%\%EXE%
    exit /b 1
)

rem Step 5: Copy runtime files (settings.cfg is the variant's own config)
echo Copying runtime files to %OUTDIR%...
copy /Y "CryptoVisionLib_xp.dll" "%OUTDIR%\CryptoVisionLib_xp.dll" >nul
copy /Y "%SETTINGS%" "%OUTDIR%\settings.cfg" >nul
for %%f in (%ENCLIST%) do copy /Y "%%f" "%OUTDIR%\" >nul
copy /Y "tags-*.cfg" "%OUTDIR%\" >nul
copy /Y "others\sha256\sha256.tcl" "%OUTDIR%\sha256.tcl" >nul
copy /Y "others\ffidl\ffidl_xp.dll" "%OUTDIR%\ffidl_xp.dll" >nul
echo package ifneeded Ffidl 0.9 [list load [file join $dir ffidl_xp.dll] Ffidl] > "%OUTDIR%\pkgIndex.tcl"
:: decrypt_helper.tcl stays out of the runtime (in-process decrypt is used)
copy /Y "third_party\json_report\json_report.exe" "%OUTDIR%\json_report.exe" >nul

rem Salt carrier: obfuscated salt shipped with the build; imported into the
rem HKCU registry on the first run, then the file is deleted.
"%TCLKIT%" crypto_utils.tcl --make-carrier --scope %SCOPE% --carrier-out "%OUTDIR%\settings.local.cfg"
if errorlevel 1 (
    echo BUILD FAILED: cannot generate settings.local.cfg carrier
    exit /b 1
)
attrib +h +s "%OUTDIR%\settings.local.cfg"

rem Ship check on the finished folder: no maintainer tools, test trees, decrypted
rem originals, working files (*.ini, *.idx) or internal notes next to the exe.
call :verify_clean "%OUTDIR%"
if errorlevel 1 exit /b 1

echo %EXE% ready in %OUTDIR%\
exit /b 0

rem ---------------------------------------------------------------------------
rem :verify_clean <dir>
rem Guard for a directory that ends up in a shipped package (the vfs payload
rem staging or a finished Build\<variant> folder): fails the build when
rem maintainer tooling, tests, decrypted originals or working files are present.
rem ---------------------------------------------------------------------------
:verify_clean
setlocal EnableDelayedExpansion
if not exist "%~1" (
    echo PAYLOAD CHECK FAILED: %~1 does not exist
    exit /b 1
)
set "BAD="
for /f "delims=" %%f in ('dir /b /s /a-d "%~1" 2^>nul') do (
    for %%n in (decrypt_helper.tcl MAINTAINER.md crypto_utils.tcl check_key.tcl encrypt_v2.tcl reencrypt_all.tcl maintainer.enabled) do (
        if /i "%%~nxf"=="%%n" set "BAD=%%~nxf"
    )
)
if defined BAD (
    echo PAYLOAD CHECK FAILED: unexpected !BAD! in %~1
    exit /b 1
)
rem Working files anywhere in the tree (*.ini / *.idx, hidden ones included)
for %%e in (ini idx) do (
    for /f "delims=" %%f in ('dir /b /s /a "%~1\*.%%e" 2^>nul') do (
        echo PAYLOAD CHECK FAILED: unexpected working file %%f in %~1
        exit /b 1
    )
)
if exist "%~1\tests" (
    echo PAYLOAD CHECK FAILED: tests directory in %~1
    exit /b 1
)
if exist "%~1\original_files" (
    echo PAYLOAD CHECK FAILED: original_files directory in %~1
    exit /b 1
)
endlocal & exit /b 0

:done
rem Every jump to :done is a failure path - return a non-zero exit code.
exit /b 1
