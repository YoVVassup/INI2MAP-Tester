# Diagnostic: run one map through main.tcl with timing.
# Usage: powershell -File tools\run_one.ps1 [-Map <name.map>]
param([string]$Map = "TEST.map")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$tclsh = "C:\tcl\bin\tclsh.exe"
$log = Join-Path $root "mission.log"
if (Test-Path $log) { Remove-Item -Force $log }
$sw = [Diagnostics.Stopwatch]::StartNew()
$p = Start-Process -FilePath $tclsh `
    -ArgumentList @("main.tcl", "--quiet", "--format", "json", $Map) `
    -WorkingDirectory $root -NoNewWindow -Wait -PassThru
Write-Host ("run {0} ms exit={1}" -f $sw.ElapsedMilliseconds, $p.ExitCode)
if (Test-Path $log) {
    $sw.Restart()
    $j = Get-Content -Raw $log | ConvertFrom-Json
    Write-Host ("json {0} ms e={1} w={2} n={3}" -f $sw.ElapsedMilliseconds, $j.summary.errors, $j.summary.warnings, $j.summary.notices)
} else {
    Write-Host "no mission.log"
}
