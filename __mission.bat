@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem  INI2MAP Tester 1.0 - Interactive launcher
rem ============================================================================
rem  Usage:
rem    __mission.bat                          - Interactive mode (select map)
rem    __mission.bat <map_file>               - Direct validation
rem    __mission.bat --baseline               - Generate baseline.log
rem    __mission.bat --baseline-filter f.map  - Validate with baseline filter
rem    __mission.bat --html <map_file>        - Validate (JSON log) + HTML report
rem    __mission.bat --help                   - Show help
rem ============================================================================

rem Check for --help
if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="" goto :interactive

rem Handle --baseline-filter with single argument (auto-use baseline.log)
if "%~1"=="--baseline-filter" (
    if "%~3"=="" (
        @tclsh main.tcl --baseline-filter baseline.log "%~2"
        goto :eof
    )
)

rem Handle --html: validate with JSON log, then render mission.html
if "%~1"=="--html" goto :html_mode

rem Direct mode: pass all arguments to tclsh
@tclsh main.tcl %*
goto :eof

:interactive
echo.
echo  ============================================
echo   INI2MAP Tester 1.0
echo  ============================================
echo.
echo   Select operation:
echo.
echo   [1] Validate map
echo   [2] Generate baseline (INI checks only)
echo   [3] Validate map with baseline filter
echo   [4] Validate + HTML report (mission.html)
echo   [0] Cancel
echo.

set /p "op=  Select operation: "

if "%op%"=="0" goto :eof
if "%op%"=="1" goto :select_map
if "%op%"=="2" goto :generate_baseline
if "%op%"=="3" goto :validate_with_filter
if "%op%"=="4" goto :select_map_html
goto :interactive

rem ============================================================================
rem  Generate baseline
rem ============================================================================
:generate_baseline
echo.
echo  ============================================
echo   Generating baseline from INI checks...
echo  ============================================
echo.

@tclsh main.tcl --baseline

set "ec=%errorlevel%"
echo.
if %ec%==0 (
    echo  [OK] Baseline generated: baseline.log
) else if %ec%==1 (
    echo  [WARN] Baseline generated with warnings. Check baseline.log
) else if %ec%==2 (
    echo  [ERROR] Baseline generated with errors. Check baseline.log
) else (
    echo  [FATAL] Baseline generation failed.
)
echo.
pause
goto :eof

rem ============================================================================
rem  Validate with baseline filter
rem ============================================================================
:validate_with_filter
echo.
echo  Checking for baseline.log...
if not exist "baseline.log" (
    echo  baseline.log not found in current directory.
    echo  Generate it first with option [2].
    echo.
    pause
    goto :interactive
)
echo  Found: baseline.log
echo.

goto :select_map_with_filter

:select_map_with_filter
echo  ============================================
echo   Select map to validate (with baseline filter)
echo  ============================================
echo.

set "map_count=0"
for %%f in (*.map *.yrm *.mpr) do (
    set /a map_count+=1
    set "map_!map_count!=%%f"
)

if %map_count%==0 (
    echo  No map files found in current directory.
    echo.
    pause
    goto :interactive
)

echo  Found %map_count% map file(s):
echo.
for /l %%i in (1,1,%map_count%) do (
    echo   [%%i] !map_%%i!
)
echo.
echo   [0] Back
echo.

set /p "choice=  Select map number: "

if "%choice%"=="0" goto :interactive
if not defined choice goto :select_map_with_filter
if %choice% lss 1 goto :select_map_with_filter
if %choice% gtr %map_count% goto :select_map_with_filter

set "selected_map=!map_%choice%!"
echo.
echo  Validating: %selected_map% (with baseline filter)
echo  ============================================
echo.

@tclsh main.tcl --baseline-filter baseline.log "%selected_map%"

set "ec=%errorlevel%"
echo.
if %ec%==0 (
    echo  [OK] Validation passed with no issues.
) else if %ec%==1 (
    echo  [WARN] Validation completed with warnings. Check mission.log
) else if %ec%==2 (
    echo  [ERROR] Validation completed with errors. Check mission.log
) else (
    echo  [FATAL] Validation failed. Check mission.log
)
echo.
pause
goto :eof

rem ============================================================================
rem  Select map (standard validation)
rem ============================================================================
:select_map
echo  ============================================
echo   Select map to validate
echo  ============================================
echo.

set "map_count=0"
for %%f in (*.map *.yrm *.mpr) do (
    set /a map_count+=1
    set "map_!map_count!=%%f"
)

if %map_count%==0 (
    echo  No map files found in current directory.
    echo  Usage: drag a .map file onto __mission.bat
    echo.
    pause
    goto :interactive
)

echo  Found %map_count% map file(s):
echo.
for /l %%i in (1,1,%map_count%) do (
    echo   [%%i] !map_%%i!
)
echo.
echo   [0] Back
echo.

set /p "choice=  Select map number: "

if "%choice%"=="0" goto :interactive
if not defined choice goto :select_map
if %choice% lss 1 goto :select_map
if %choice% gtr %map_count% goto :select_map

set "selected_map=!map_%choice%!"
echo.
echo  Validating: %selected_map%
echo  ============================================
echo.

@tclsh main.tcl "%selected_map%"

set "ec=%errorlevel%"
echo.
if %ec%==0 (
    echo  [OK] Validation passed with no issues.
) else if %ec%==1 (
    echo  [WARN] Validation completed with warnings. Check mission.log
) else if %ec%==2 (
    echo  [ERROR] Validation completed with errors. Check mission.log
) else (
    echo  [FATAL] Validation failed. Check mission.log
)
echo.
pause
goto :eof

rem ============================================================================
rem  Select map (validation + HTML report)
rem ============================================================================
:select_map_html
echo  ============================================
echo   Select map to validate + HTML report
echo  ============================================
echo.

set "map_count=0"
for %%f in (*.map *.yrm *.mpr) do (
    set /a map_count+=1
    set "map_!map_count!=%%f"
)

if %map_count%==0 (
    echo  No map files found in current directory.
    echo.
    pause
    goto :interactive
)

echo  Found %map_count% map file(s):
echo.
for /l %%i in (1,1,%map_count%) do (
    echo   [%%i] !map_%%i!
)
echo.
echo   [0] Back
echo.

set /p "choice=  Select map number: "

if "%choice%"=="0" goto :interactive
if not defined choice goto :select_map_html
if %choice% lss 1 goto :select_map_html
if %choice% gtr %map_count% goto :select_map_html

set "selected_map=!map_%choice%!"
echo.
echo  Validating: %selected_map% (JSON log + HTML report)
echo  ============================================
echo.

@tclsh main.tcl --format json --no-log-open "%selected_map%"

set "ec=%errorlevel%"
echo.
if %ec%==0 (
    echo  [OK] Validation passed with no issues.
) else if %ec%==1 (
    echo  [WARN] Validation completed with warnings. Check mission.log
) else if %ec%==2 (
    echo  [ERROR] Validation completed with errors. Check mission.log
) else (
    echo  [FATAL] Validation failed. Check mission.log
)
if not exist "mission.log" (
    echo  [ERROR] mission.log not found - HTML report skipped.
) else if not exist "json_report.exe" (
    echo  [ERROR] json_report.exe not found in project root. Run build.bat first.
) else (
    json_report.exe -open mission.log
    if errorlevel 1 (
        echo  [ERROR] HTML report failed.
    ) else (
        echo  [OK] HTML report opened: mission.html
    )
)
echo.
pause
goto :eof

rem ============================================================================
rem  Validate with JSON log + HTML report (direct mode: --html <map_file>)
rem ============================================================================
:html_mode
if "%~2"=="" (
    echo Usage: __mission.bat --html ^<map_file^>
    exit /b 1
)
@tclsh main.tcl --format json --no-log-open "%~2"
set "ec=%errorlevel%"
for %%f in ("%~2") do set "mapdir=%%~dpf"
echo.
if not exist "!mapdir!mission.log" (
    echo  [ERROR] mission.log not found in !mapdir!
    exit /b 3
)
if not exist "json_report.exe" (
    echo  [ERROR] json_report.exe not found in project root. Run build.bat first.
    exit /b 3
)
json_report.exe -open "!mapdir!mission.log"
if errorlevel 1 (
    echo  [ERROR] HTML report failed. See messages above.
    exit /b 3
)
echo  [OK] HTML report opened: !mapdir!mission.html
exit /b %ec%

:show_help
echo.
echo  INI2MAP Tester 1.0 - Map validation tool for RA2/YR
echo.
echo  Usage:
echo    __mission.bat                          Interactive mode
echo    __mission.bat ^<map_file^>               Validate a single map
echo    __mission.bat --mode ^<mode^> ^<map_file^>  Set game mode
echo    __mission.bat --baseline               Generate baseline.log
echo    __mission.bat --baseline-filter ^<file^> Validate with baseline filter
echo    __mission.bat --batch ^<pattern^>        Validate multiple maps
echo    __mission.bat --html ^<map_file^>        Validate + HTML report (mission.html)
echo    __mission.bat --quiet ^<map_file^>       Suppress console output
echo    __mission.bat --help                   Show this help
echo.
echo  Exit codes:
echo    0   Validation passed with no issues
echo    1   Validation completed with warnings only
echo    2   Validation completed with errors
echo    3   Fatal error (unhandled exception)
echo.
echo  Supported formats: .map, .yrm, .mpr
echo.
goto :eof
