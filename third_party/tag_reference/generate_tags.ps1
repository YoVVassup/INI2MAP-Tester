<#
.SYNOPSIS
    Generates taglist whitelist configs (tags-*.cfg) from the Tag Reference workbook.

.DESCRIPTION
    Reads third_party\tag_reference\tag_reference.xlsx (sheet "Tag Reference") and
    writes tags-ra2.cfg, tags-yr.cfg, tags-ares.cfg, tags-phobos.cfg and clears
    tags-ext.cfg (auto-append file).

    Columns: Section | Tag | RA2 | YR | Ares | Phobos | Ext | Games
    A tag is written to a config when the corresponding column contains "X".

    Tags containing placeholders ([House], [Side], [Plane_Index], [List_Index],
    [Armor_Name]) are NOT written literally; they become regular expression lines
    taken from Regular_to_Excel.txt (plus one derived rule for ParaDrop without a
    .Plane<N> segment). Regex lines start with "^".

.EXAMPLE
    powershell -File third_party\tag_reference\generate_tags.ps1

.EXAMPLE
    powershell -File third_party\tag_reference\generate_tags.ps1 -OutDir C:\work\map -Verbose
#>
[CmdletBinding()]
param(
    [string]$Source,
    [string]$RegexSource,
    [string]$OutDir,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Source)      { $Source      = Join-Path $here 'tag_reference.xlsx' }
if (-not $RegexSource) { $RegexSource = Join-Path $here 'Regular_to_Excel.txt' }
if (-not $OutDir)      { $OutDir      = Split-Path -Parent (Split-Path -Parent $here) }

if (-not (Test-Path -LiteralPath $Source))      { throw "Source workbook not found: $Source" }
if (-not (Test-Path -LiteralPath $RegexSource)) { throw "Regex source not found: $RegexSource" }

$sectionOrder = @(
    'InfantryTypes', 'VehicleTypes', 'AircraftTypes', 'BuildingTypes',
    'Warheads', 'Weapons', 'Projectiles', 'ParticleSystems', 'Particles',
    'SuperWeaponTypes', 'Animations', 'VoxelAnims',
    'AttachEffectTypes', 'RadiationTypes', 'ShieldTypes'
)

$modes = @(
    @{ File = 'tags-ra2.cfg';      Flag = 'RA2';     Title = 'RA2 (vanilla)' },
    @{ File = 'tags-yr.cfg';       Flag = 'YR';      Title = "Yuri's Revenge (vanilla)" },
    @{ File = 'tags-ares.cfg';     Flag = 'Ares';    Title = 'Ares patch' },
    @{ File = 'tags-phobos.cfg';   Flag = 'Phobos';  Title = 'Phobos-only extras (loaded on top of tags-ares.cfg)' }
)

# --- read workbook -----------------------------------------------------------
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Read-ZipEntry {
    param([System.IO.Compression.ZipArchive]$Zip, [string]$Name)
    $entry = $Zip.GetEntry($Name)
    if (-not $entry) { throw "Entry '$Name' not found inside $Source" }
    $reader = New-Object System.IO.StreamReader($entry.Open())
    try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}

$zip = [System.IO.Compression.ZipFile]::OpenRead($Source)
try {
    [xml]$sharedXml = $null
    $sharedEntry = $zip.GetEntry('xl/sharedStrings.xml')
    if ($sharedEntry) {
        $reader = New-Object System.IO.StreamReader($sharedEntry.Open())
        try { [xml]$sharedXml = $reader.ReadToEnd() } finally { $reader.Dispose() }
    }

    # Resolve the worksheet by its NAME ("Tag Reference") via workbook.xml and
    # workbook.xml.rels instead of assuming the physical part name
    # 'xl/worksheets/sheet1.xml' - Excel may store any sheet as sheetN.xml.
    [xml]$wbXml     = Read-ZipEntry $zip 'xl/workbook.xml'
    [xml]$wbRelsXml = Read-ZipEntry $zip 'xl/_rels/workbook.xml.rels'

    $sheetNode = $null
    $sheetName = $null
    foreach ($s in @($wbXml.workbook.sheets.sheet)) {
        foreach ($attr in $s.Attributes) {
            if ($attr.LocalName -eq 'name' -and $attr.Value -eq 'Tag Reference') {
                $sheetNode = $s
                $sheetName = $attr.Value
                break
            }
        }
        if ($sheetNode) { break }
    }
    if (-not $sheetNode) {
        Write-Warning "Worksheet 'Tag Reference' not found; falling back to the first sheet of the workbook."
        $sheetNode = @($wbXml.workbook.sheets.sheet) | Select-Object -First 1
    }
    if (-not $sheetNode) { throw "No <sheet> entries found in xl/workbook.xml" }

    $rid = $null
    foreach ($attr in $sheetNode.Attributes) {
        if ($attr.LocalName -eq 'id') { $rid = $attr.Value; break }
    }
    if (-not $rid) { throw "Worksheet '$sheetName' in workbook.xml has no r:id attribute" }

    $rel = $wbRelsXml.Relationships.Relationship | Where-Object { $_.Id -eq $rid } | Select-Object -First 1
    if (-not $rel) { throw "Relationship '$rid' not found in xl/_rels/workbook.xml.rels" }

    $target = ([string]$rel.Target) -replace '\\', '/'
    if ($target.StartsWith('/'))       { $sheetPath = $target.TrimStart('/') }
    elseif ($target.StartsWith('xl/')) { $sheetPath = $target }
    else                               { $sheetPath = "xl/$target" }
    [xml]$sheetXml  = Read-ZipEntry $zip $sheetPath
    Write-Verbose "Worksheet '$sheetName' resolved to part '$sheetPath'"
} finally {
    $zip.Dispose()
}

$shared = New-Object System.Collections.Generic.List[string]
if ($sharedXml) {
    foreach ($si in $sharedXml.sst.si) {
        if ($null -ne $si.t) {
            $shared.Add([string]$si.t)
        } else {
            $text = ''
            foreach ($run in @($si.r)) { $text += [string]$run.t }
            $shared.Add($text)
        }
    }
}

$columnIndex = @{ A = 0; B = 1; C = 2; D = 3; E = 4; F = 5; G = 6; H = 7 }
$records = New-Object System.Collections.Generic.List[object]

foreach ($row in @($sheetXml.worksheet.sheetData.row)) {
    $values = @('', '', '', '', '', '', '', '')
    foreach ($cell in @($row.c)) {
        if (-not $cell.r) { continue }
        $col = ([regex]::Match([string]$cell.r, '^[A-Z]+')).Value
        if (-not $columnIndex.ContainsKey($col)) { continue }
        $text = ''
        switch ([string]$cell.t) {
            's'          { $text = $shared[[int]$cell.v] }
            'inlineStr'  { $text = [string]$cell.is.t }
            default      { if ($null -ne $cell.v) { $text = [string]$cell.v } }
        }
        $values[$columnIndex[$col]] = $text
    }
    $tag = $values[1].Trim()
    if ($values[0].Trim() -eq 'Section' -and $tag -eq 'Tag') { continue }   # header row
    if ($tag -eq '') { continue }   # spacer rows

    $records.Add([pscustomobject]@{
        Section = $values[0].Trim()
        Tag     = $tag
        RA2     = $values[2].Trim()
        YR      = $values[3].Trim()
        Ares    = $values[4].Trim()
        Phobos  = $values[5].Trim()
        Ext     = $values[6].Trim()
        Games   = $values[7].Trim()
    })
}

if (-not $records.Count) { throw 'No data rows read from the workbook.' }

$bad = @($records | Where-Object { $sectionOrder -notcontains $_.Section })
if ($bad.Count) {
    throw ("Unknown section(s) in workbook: " + (($bad | ForEach-Object { $_.Section } | Sort-Object -Unique) -join ', '))
}
$dupes = @($records | Group-Object Section, Tag | Where-Object Count -gt 1)
if ($dupes.Count) {
    throw ("Duplicate Section/Tag rows in workbook: " + (($dupes | ForEach-Object Name) -join '; '))
}
Write-Verbose "Read $($records.Count) data rows from '$(Split-Path -Leaf $Source)'."

# --- regular expressions for placeholder tags --------------------------------
$fileRegexes = @(
    Get-Content -LiteralPath $RegexSource |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and -not $_.StartsWith(';') }
)
if ($fileRegexes.Count -lt 3) { throw "Expected at least 3 regexes in $RegexSource, got $($fileRegexes.Count)." }

$plainParaDropRegex = '^ParaDrop\.([A-Za-z0-9_-]+)\.(Aircraft|Count|Num|Types)$'

# rule name -> selector over the template row (which file regex covers it)
$rules = @(
    @{ Name = 'paraDropPlane'; Pattern = '^ParaDrop\.\[(House|Side)\]\.Plane\[Plane_Index\]\.'; FromFile = $true;  Match = 'ParaDrop' },
    @{ Name = 'paraDropPlain'; Pattern = '^ParaDrop\.\[(House|Side)\]\.(Aircraft|Count|Num|Types)$'; FromFile = $false; Regex = $plainParaDropRegex },
    @{ Name = 'prereqList';    Pattern = '^Prerequisite\.List\[List_Index\]$';                  FromFile = $true;  Match = 'Prerequisite' },
    @{ Name = 'versus';        Pattern = '^Versus\.\[Armor_Name\]';                             FromFile = $true;  Match = 'Versus' },
    @{ Name = 'convertIndex';  Pattern = '^Convert\[Index\]\.(From|To|AffectedHouses)$';         FromFile = $true;  Match = 'Convert' },
    @{ Name = 'limboWeights';  Pattern = '^LimboDelivery\.RandomWeights\[Index\]$';               FromFile = $true;  Match = 'LimboDelivery' },
    @{ Name = 'swNextWeights'; Pattern = '^SW\.Next\.RandomWeights\[Index\]$';                    FromFile = $true;  Match = 'SW\.Next' },
    @{ Name = 'spawnsCrate';   Pattern = '^SpawnsCrate\[Index\]\.(Type|Weight)$';                 FromFile = $true;  Match = 'SpawnsCrate' },
    @{ Name = 'insigniaFrame';  Pattern = '^InsigniaFrame\.\[Weapon_Index\](\.(Rookie|Veteran|Elite))?$'; FromFile = $true; Match = 'InsigniaFrame\.Weapon' },
    @{ Name = 'insigniaFrames'; Pattern = '^InsigniaFrames\.\[Weapon_Index\]$';                    FromFile = $true;  Match = 'InsigniaFrames\.Weapon' },
    @{ Name = 'insignia';       Pattern = '^Insignia\.\[Weapon_Index\](\.(Rookie|Veteran|Elite))?$'; FromFile = $true;  Match = 'Insignia\.Weapon' }
)

$ruleRegex = @{}
foreach ($rule in $rules) {
    if ($rule.FromFile) {
        $hits = @($fileRegexes | Where-Object { $_ -like "*$($rule.Match)*" })
        if ($hits.Count -ne 1) {
            throw "Regex source: expected exactly 1 pattern containing '$($rule.Match)', got $($hits.Count)."
        }
        $ruleRegex[$rule.Name] = $hits[0]
    } else {
        $ruleRegex[$rule.Name] = [string]$rule.Regex
    }
    [void][regex]::new([string]$ruleRegex[$rule.Name])   # compile check
}

$orphan = @($fileRegexes | Where-Object {
    $text = $_
    -not (@($rules | Where-Object { $_.FromFile -and $text -like "*$($_.Match)*" }).Count)
})
if ($orphan.Count) { throw "Regex source: unused pattern(s): $($orphan -join ' | ')" }

# place-holders -> sample values used to prove each template is covered
$samples = @{
    '[House]'       = 'GDI'
    '[Side]'        = 'Allied'
    '[Plane_Index]' = '2'
    '[List_Index]'  = '1'
    '[Armor_Name]'  = 'Wood'
    '[Index]'       = '0'
    '[Weapon_Index]' = 'Weapon0'
}

$literalTags = @()          # rows without placeholders
$dynamicRows = @()          # rows with placeholders -> need a regex

foreach ($rec in $records) {
    if ($rec.Tag -match '\[[A-Za-z_]+\]') { $dynamicRows += $rec } else { $literalTags += $rec }
}

$ruleOfRow = @{}
foreach ($rec in $dynamicRows) {
    $matched = @($rules | Where-Object { $rec.Tag -match $_.Pattern })
    if ($matched.Count -ne 1) {
        throw "Unhandled placeholder tag '$($rec.Tag)' (matched $($matched.Count) rules)."
    }
    $ruleName = $matched[0].Name
    $ruleOfRow["$($rec.Section)|$($rec.Tag)"] = $ruleName

    $sample = $rec.Tag
    foreach ($ph in $samples.Keys) { $sample = $sample.Replace($ph, $samples[$ph]) }
    $rx = [regex]::new([string]$ruleRegex[$ruleName])
    if (-not $rx.IsMatch($sample)) {
        throw "Regex '$($ruleRegex[$ruleName])' does not match sample '$sample' of template '$($rec.Tag)'."
    }
}
Write-Verbose "$($literalTags.Count) literal tags, $($dynamicRows.Count) placeholder tags ($($rules.Count) rules)."

# --- build per-config content ------------------------------------------------
$flagOfMode = @{}
foreach ($m in $modes) { $flagOfMode[$m.Flag] = $m.Flag }

$configs = @{}
foreach ($m in $modes) {
    $configs[$m.File] = [ordered]@{}
    foreach ($sec in $sectionOrder) { $configs[$m.File][$sec] = @{ Tags = New-Object System.Collections.Generic.List[string]; Regexes = New-Object System.Collections.Generic.List[string] } }
}

function Add-Entry {
    param([string]$File, [string]$Section, [string]$Entry)
    $slot = $configs[$File][$Section]
    if (-not $slot.Tags.Contains($Entry) -and -not $slot.Regexes.Contains($Entry)) {
        $slot.Tags.Add($Entry)
    }
}

function Add-RegexEntry {
    param([string]$File, [string]$Section, [string]$Pattern)
    $slot = $configs[$File][$Section]
    if (-not $slot.Regexes.Contains($Pattern)) { $slot.Regexes.Add($Pattern) }
}

foreach ($rec in $literalTags) {
    foreach ($m in $modes) {
        if ($rec.($m.Flag) -eq 'X') { Add-Entry -File $m.File -Section $rec.Section -Entry $rec.Tag }
    }
    if ($rec.RA2 -ne 'X' -and $rec.YR -ne 'X' -and $rec.Ares -ne 'X' -and $rec.Phobos -ne 'X') {
        throw "Row '$($rec.Section)/$($rec.Tag)' has no game flags set."
    }
}

foreach ($rec in $dynamicRows) {
    $ruleName = $ruleOfRow["$($rec.Section)|$($rec.Tag)"]
    $pattern  = [string]$ruleRegex[$ruleName]
    foreach ($m in $modes) {
        if ($rec.($m.Flag) -ne 'X') { continue }
        $slot = $configs[$m.File][$rec.Section]
        # no literal tag may be swallowed by the pattern of the same section
        foreach ($lit in $slot.Tags) {
            if ([regex]::new($pattern).IsMatch($lit)) {
                throw "Literal tag '$lit' in '$($rec.Section)' would also match regex '$pattern'."
            }
        }
        Add-RegexEntry -File $m.File -Section $rec.Section -Pattern $pattern
    }
}

# --- write -------------------------------------------------------------------
function Sort-Tags {
    param([System.Collections.Generic.List[string]]$List)
    return @($List | Sort-Object -Property @{ Expression = { $_.ToLowerInvariant() } }, @{ Expression = { $_ } })
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$summary = @()

foreach ($m in $modes) {
    $file = Join-Path $OutDir $m.File
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("; TAGLIST tag whitelist - $($m.Title)")
    $lines.Add("; Generated from third_party\tag_reference\tag_reference.xlsx (sheet 'Tag Reference'),")
    $lines.Add("; column $($m.Flag). Source of truth - do not edit by hand;")
    $lines.Add("; regenerate with: powershell -File third_party\tag_reference\generate_tags.ps1")
    $lines.Add("; Lines starting with ^ are regular expressions for dynamic (placeholder) tag names.")
    $lines.Add("; tags-ext.cfg holds tags discovered at runtime and is reset by the same script.")
    $lines.Add("")

    $tagCount = 0
    $regexCount = 0
    foreach ($sec in $sectionOrder) {
        $slot = $configs[$m.File][$sec]
        if ($slot.Tags.Count -eq 0 -and $slot.Regexes.Count -eq 0) { continue }
        $lines.Add("[$sec]")
        foreach ($t in (Sort-Tags $slot.Tags)) { $lines.Add($t) }
        foreach ($rx in @($slot.Regexes | Sort-Object)) { $lines.Add($rx) }
        $tagCount   += $slot.Tags.Count
        $regexCount += $slot.Regexes.Count
    }

    $summary += [pscustomobject]@{ File = $m.File; Sections = @($sectionOrder | Where-Object { $configs[$m.File][$_].Tags.Count -or $configs[$m.File][$_].Regexes.Count }).Count; Tags = $tagCount; Regexes = $regexCount }

    if ($DryRun) {
        Write-Host "would write $file ($tagCount tags, $regexCount regexes)"
    } else {
        [System.IO.File]::WriteAllText($file, (($lines -join "`n") + "`n"), $utf8NoBom)
        Write-Verbose "wrote $file"
    }
}

# tags-ext.cfg is the runtime auto-append file; the workbook's Ext column is unused
$extFile = Join-Path $OutDir 'tags-ext.cfg'
$extLines = @(
    '; TAGLIST auto-append file (tags-ext.cfg)'
    '; Unknown tags found during validation are appended here automatically'
    '; (see ::TagList::_write_new_tags). The Ext column of'
    '; third_party\tag_reference\tag_reference.xlsx is not used, so this file'
    '; is empty right after regeneration.'
    ';'
)
if ($DryRun) {
    Write-Host "would reset $extFile"
} else {
    [System.IO.File]::WriteAllText($extFile, (($extLines -join "`n") + "`n"), $utf8NoBom)
}

$summary += [pscustomobject]@{ File = 'tags-ext.cfg'; Sections = 0; Tags = 0; Regexes = 0 }
$summary | Format-Table -AutoSize
Write-Host "Output directory: $OutDir"
