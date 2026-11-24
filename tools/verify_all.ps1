# Full pre-submit verification for INI2MAP Tester.
# Usage: powershell -File tools\verify_all.ps1 [-E2E] [-Fuzz]
#   1. README boxes + encodings        (tools/check_boxes.py)
#   2. INI2MAP-Tester.vfs mirror sync + MD5   (tools/sync_vfs.ps1)
#   3. unit test suite                 (tests/run_all.tcl)
#   -E2E additionally runs the slow gates:
#     4. E2E baselines                 (tests/run_e2e.tcl)
#     5. built-exe smoke, if Build\MOMT\MOMT.exe exists (tests/run_e2e.tcl -exe)
#   -Fuzz runs the slow map fuzzer     (tests/fuzz_maps.tcl)
# Switches are independent and can be combined: -E2E -Fuzz runs everything.
param([switch]$E2E, [switch]$Fuzz)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$tclsh = "C:\tcl\bin\tclsh.exe"
$fail = 0

Write-Host "--- check_boxes.py ---"
& python (Join-Path $here "check_boxes.py")
if ($LASTEXITCODE -ne 0) { $fail++ }

Write-Host "--- sync_vfs.ps1 ---"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here "sync_vfs.ps1")
if ($LASTEXITCODE -ne 0) { $fail++ }

Write-Host "--- tests/run_all.tcl ---"
Push-Location $root
try {
    & $tclsh "tests\run_all.tcl"
    $rc = $LASTEXITCODE
}
finally { Pop-Location }
if ($rc -ne 0) { $fail++ }

if ($E2E) {
    Write-Host "--- tests/run_e2e.tcl ---"
    Push-Location $root
    try {
        & $tclsh "tests\run_e2e.tcl"
        $rc = $LASTEXITCODE
    }
    finally { Pop-Location }
    if ($rc -ne 0) { $fail++ }

    if (Test-Path -LiteralPath (Join-Path $root "Build\MOMT\MOMT.exe")) {
        Write-Host "--- tests/run_e2e.tcl -exe (smoke) ---"
        Push-Location $root
        try {
            & $tclsh "tests\run_e2e.tcl" "-exe"
            $rc = $LASTEXITCODE
        }
        finally { Pop-Location }
        if ($rc -ne 0) { $fail++ }
    }
    else {
        Write-Host "--- smoke skipped (no Build\MOMT\MOMT.exe, run build.bat first) ---"
    }
}

if ($Fuzz) {
    Write-Host "--- tests/fuzz_maps.tcl ---"
    Push-Location $root
    try {
        & $tclsh "tests\fuzz_maps.tcl"
        $rc = $LASTEXITCODE
    }
    finally { Pop-Location }
    if ($rc -ne 0) { $fail++ }
}

if ($fail -gt 0) {
    Write-Host ("verify_all: {0} step(s) FAILED" -f $fail)
    exit 1
}
Write-Host "verify_all: OK"
exit 0
