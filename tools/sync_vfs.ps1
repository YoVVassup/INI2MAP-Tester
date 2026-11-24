# Sync the INI2MAP-Tester.vfs mirror from the project root using the build.bat step-0
# whitelist (parsed from build.bat, so the two can never drift apart) and
# verify every mirrored file byte-for-byte (MD5). Reports missing, differing
# and stale (mirrored but absent from source) files. Output: "synced N/M".
# Usage: powershell -File tools\sync_vfs.ps1
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$bat = Join-Path $root "build.bat"

# --- Step 1: parse the step-0 robocopy whitelist out of build.bat ---
$ops = @()
foreach ($line in (Get-Content -LiteralPath $bat)) {
    $t = $line.Trim()
    if (-not $t.StartsWith("robocopy ")) { continue }
    if ($t -notlike "*INI2MAP-Tester.vfs*") { continue }
    $tokens = @()
    foreach ($m in [regex]::Matches($t, '"([^"]*)"|(\S+)')) {
        if ($m.Groups[1].Success) { $tokens += $m.Groups[1].Value }
        else { $tokens += $m.Groups[2].Value }
    }
    $src = $tokens[1]
    $dst = $tokens[2]
    $files = @()
    $recurse = $false
    $purge = $false
    foreach ($tok in ($tokens | Select-Object -Skip 3)) {
        if ($tok -like "/*") {
            if ($tok -ieq "/E") { $recurse = $true }
            if ($tok -ieq "/PURGE") { $purge = $true }
        }
        elseif ($tok -match '^[<>]') { }        # shell redirection (">nul")
        else { $files += $tok }
    }
    $ops += ,@{ Src = $src; Dst = $dst; Files = $files; Recurse = $recurse; Purge = $purge }
}
if ($ops.Count -eq 0) { throw "no step-0 robocopy lines found in build.bat" }

# --- Step 2: run the same robocopy operations ---
Push-Location $root
try {
    foreach ($op in $ops) {
        $rbArgs = @($op.Src, $op.Dst) + $op.Files
        if ($op.Recurse) { $rbArgs += "/E" }
        if ($op.Purge) { $rbArgs += "/PURGE" }
        $rbArgs += @("/njh", "/njs", "/ndl", "/nc", "/ns", "/np")
        & robocopy @rbArgs | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy $($op.Src) -> $($op.Dst) failed (rc=$LASTEXITCODE)" }
    }

    # --- Step 3: verify source vs mirror with MD5 (old PS has no Get-FileHash) ---
    $md5 = [System.Security.Cryptography.MD5]::Create()
    function FileMd5($path) {
        $fs = [System.IO.File]::OpenRead($path)
        try { return [BitConverter]::ToString($md5.ComputeHash($fs)) }
        finally { $fs.Close() }
    }

    $pairs = @()
    $expectedDst = @{}          # dst full path -> $true (for the stale scan)
    foreach ($op in $ops) {
        $srcDir = Join-Path $root $op.Src
        $dstDir = Join-Path $root $op.Dst
        $recursive = $op.Recurse
        if ($op.Files.Count -gt 0) {
            foreach ($f in $op.Files) {
                if ($f -like "*`*") {
                    foreach ($m in (Get-ChildItem -LiteralPath $srcDir -Filter $f -File)) {
                        $dstFile = Join-Path $dstDir $m.Name
                        $pairs += ,@($m.FullName, $dstFile)
                        $expectedDst[$dstFile.ToLower()] = $true
                    }
                }
                else {
                    $dstFile = Join-Path $dstDir $f
                    $pairs += ,@((Join-Path $srcDir $f), $dstFile)
                    $expectedDst[$dstFile.ToLower()] = $true
                }
            }
        }
        else {
            $recursive = $true
        }
        if ($recursive) {
            $srcFull = (Resolve-Path -LiteralPath $srcDir).Path
            $dstFull = (Resolve-Path -LiteralPath $dstDir).Path
            foreach ($m in (Get-ChildItem -LiteralPath $srcFull -Recurse -File)) {
                $rel = $m.FullName.Substring($srcFull.Length + 1)
                $dstFile = Join-Path $dstFull $rel
                $pairs += ,@($m.FullName, $dstFile)
                $expectedDst[$dstFile.ToLower()] = $true
            }
        }
    }

    $same = 0
    $bad = @()
    foreach ($p in $pairs) {
        $src = $p[0]; $dst = $p[1]
        if (!(Test-Path -LiteralPath $dst)) { $bad += "missing: $dst"; continue }
        if ((FileMd5 $src) -ne (FileMd5 $dst)) { $bad += "differs: $dst"; continue }
        $same++
    }

    # Mirror files that no source file maps to (build.bat never purges the
    # whitelist dirs, so these would ship inside the starpack as-is).
    $stale = @()
    foreach ($op in $ops) {
        $dstDir = (Resolve-Path -LiteralPath (Join-Path $root $op.Dst)).Path
        $scan = if ($op.Recurse) { Get-ChildItem -LiteralPath $dstDir -Recurse -File } `
                else { Get-ChildItem -LiteralPath $dstDir -File }
        foreach ($m in $scan) {
            if (!$expectedDst.ContainsKey($m.FullName.ToLower())) { $stale += $m.FullName }
        }
    }

    Write-Host ("synced {0}/{1}" -f $same, $pairs.Count)
    foreach ($b in $bad) { Write-Host "  MISMATCH $b" }
    foreach ($s in $stale) { Write-Host "  STALE (no source file): $s" }
    if ($bad.Count -gt 0 -or $stale.Count -gt 0) { exit 1 }
    exit 0
}
finally {
    Pop-Location
}
