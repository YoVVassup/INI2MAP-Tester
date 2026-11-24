<p align="center">
  <h1 align="center">INI2MAP Tester</h1>
  <p align="center">Map validation tool for Command & Conquer Red Alert 2 / Yuri's Revenge modding</p>
</p>

<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/English-blue" alt="English"></a>
  <a href="README.ru.md"><img src="https://img.shields.io/badge/Русский-earlapblue" alt="Русский"></a>
  <a href="README.zh.md"><img src="https://img.shields.io/badge/中文-d73a49" alt="中文"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Tcl-8.6-blue?logo=tcl&logoColor=white" alt="Tcl">
  <img src="https://img.shields.io/badge/Platform-Windows-0078d4?logo=windows&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/Crypto-NaCl--XSalsa20-green" alt="Crypto">
  <img src="https://img.shields.io/badge/Encryption-V2--HKDF--SHA256-orange" alt="Encryption">
  <img src="https://img.shields.io/badge/Maps-124%2B%20checks-brightgreen" alt="Checks">
  <img src="https://img.shields.io/badge/Tests-1124%2F1124%20passing-success" alt="Tests">
  <img src="https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-blue" alt="License">
</p>

---

<p align="center">
  <b>Decrypt • Parse • Validate • Report</b>
</p>

---

## Features

```
┌─────────────────────────────────────────────────────────────────┐
│  🔐 ENCRYPTION                                                  │
│  ├── V2 Multi-Factor: DLL hash + salt + HKDF-SHA256             │
│  ├── V1 Legacy: DEFAULT_KEY (XSalsa20 + Poly1305)               │
│  └── Auto-detection by "CV02" magic bytes                       │
├─────────────────────────────────────────────────────────────────┤
│  📁 FILE SUPPORT                                                │
│  ├── Maps: .map, .yrm, .mpr                                     │
│  ├── Rules: .enc (encrypted INI)                                │
│  └── Audio: .enc (encrypted .idx)                               │
├─────────────────────────────────────────────────────────────────┤
│  ✅ VALIDATION                                                  │
│  ├── 124 structural checks (weapons, warheads, animations)      │
│  ├── AI cross-checks (prerequisites, references, colors)        │
│  ├── 26 WAE map checks + trigger integrity                      │
│  ├── Sound resource validation                                  │
│  └── Batch mode with JSON summary                               │
├─────────────────────────────────────────────────────────────────┤
│  🎮 GAME MODES                                                  │
│  ├── RA2 (Red Alert 2)                                          │
│  ├── YR (Yuri's Revenge)                                        │
│  ├── Ares (mod extension)                                       │
│  └── Phobos (mod extension)                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Requirements

```
┌─────────────────────────────────────────────────────────────────┐
│  PREREQUISITES                                                  │
│                                                                 │
│  ✓ ActiveTcl 8.6 (32-bit)                                       │
│    └── tclsh86.exe must be in PATH or launched directly         │
│                                                                 │
│  ✓ ffidl_xp.dll (XP-compatible FFI, self-contained)             │
│    └── Provided in others/ffidl/                                │
│                                                                 │
│  ✓ CryptoVisionLib_xp.dll (XP-compatible, statically linked)    │
│    └── Provided in third_party/CryptoVisionLib/                 │
│                                                                 │
│  ○ PatchDll.exe (optional)                                      │
│    └── Only needed for re-keying encryption                     │
└─────────────────────────────────────────────────────────────────┘
```

## File Structure

```
<project dir>\
│
├── 📄 main.tcl                  Entry point
├── 📄 __mission.bat             Interactive launcher
├── 📄 settings.cfg              MOMT configuration (hash, salt, game mode)
├── 📄 settings-ra2.cfg          RA2MT configuration (same hash/salt, RA2 files)
├── 📄 settings-yr.cfg           RA2YRMT configuration (same hash/salt, YR files)
├── 🎨 MOMT.ico                  Application icon (MOMT build)
├── 🎨 RA2MT.ico                 Application icon (RA2MT build)
├── 🎨 RA2YRMT.ico               Application icon (RA2YRMT build)
│
├── 📁 original_files/           Original plaintext files for re-encryption
│   ├── Mental Omega/            9 files: rulesmo, aimo, artmo, soundmo, thememo, evamo, audio*
│   ├── Red Alert 2/             7 files: rules, ai, art, sound, theme, eva, audio_ra2
│   └── Red Alert 2 Yuris Revenge/  8 files: rulesmd, aimd, artmd, soundmd, thememd, evamd, audio*
│
├── 🔒 rulesmo.enc               Encrypted rules set - MOMT (rulesmo, aimo, artmo, soundmo, thememo, evamo)
├── 🔒 rules.enc                 Encrypted rules set - RA2MT (rules, ai, art, sound, theme, eva)
├── 🔒 rulesmd.enc               Encrypted rules set - RA2YRMT (rulesmd, aimd, artmd, soundmd, thememd, evamd)
├── 🔒 audio_ra2.enc             Audio indexes (audio_ra2, audio_yr, audio - shared by all variants)
│
├── 📄 crypto.tcl                Crypto module (ffidl + DLL integration)
├── 📄 crypto_utils.tcl          Standalone encrypt/decrypt utility
├── 📄 cli.tcl                   Command-line argument parser
├── 📄 config.tcl                Settings loader
├── 📄 constants.tcl             Game constants
├── 📄 data.tcl                  Global data arrays
├── 📄 logging.tcl               Log writer
├── 📄 orchestrator.tcl          Main validation orchestrator
├── 📄 cache.tcl                 Rules/audio caching for batch mode
├── 📄 utils.tcl                 Shared utility procs
├── 📄 audio_parser.tcl          Audio index parser (decrypts .enc in memory)
├── 📄 rules_parser.tcl          Rules INI parser
├── 📁 rules_parser/             Rules parser sub-modules (8 files)
├── 📄 map_parser.tcl            Map file parser
├── 📁 map_parser/               Map parser sub-modules (10 files)
├── 📄 validators.tcl            Validator dispatcher
├── 📁 validators/               Validator modules (9 files)
├── 📄 checks.tcl                Check dispatcher + index builder
├── 📁 checks/                   Check modules (125 files: 124 modules + loader)
├── 📁 aicheck/                  AI cross-check modules (7 files: 5 modules + aicheck.tcl + core.tcl)
├── 📁 taglist/                  Tag validation configs
├── 📁 others/                   External dependencies
│   ├── ffidl/                   ffidl FFI package (ffidl_xp.dll + pkgIndex.tcl)
│   └── sha256/                  SHA-256 package for Tcl
├── 📁 third_party/              Third-party source code & build scripts
│   ├── CryptoVisionLib/         Crypto DLL source + build_xp.bat
│   ├── ffidl/                   ffidl source + build_xp.bat
│   ├── json_report/             JSON log -> HTML report source + build_xp.bat
│   ├── patch_key/               PatchDll source + build_xp.bat
│   └── tag_reference/           Tag Reference workbook + generate_tags.ps1
├── 📁 tools/                    Build binaries + verification scripts (sync/verify/check/run_one)
├── 📁 tests/                    Test files (131 files, 1124 tests)
└── 📁 Build/                    Built self-contained executables (build.bat)
    ├── RA2MT/                   RA2MT.exe + settings.cfg + its .enc set + DLL + helpers
    ├── RA2YRMT/                 RA2YRMT.exe + settings.cfg + its .enc set + DLL + helpers
    └── MOMT/                    MOMT.exe + settings.cfg + its .enc set + DLL + helpers
```

## Quick Start

### Run validation on a single map

```bash
cd /d <project dir>
tclsh86.exe main.tcl all01.map
```

If `tclsh86` is not on PATH, point to your interpreter explicitly (everything else stays relative):

```bash
"path\to\tclsh86.exe" main.tcl all01.map
```

**Example output:**

```
sha256 loaded.
Game directory: <project dir>
  rules: rulesmo.enc (ok)
  ai: aimo.enc (ok)
  art: artmo.enc (ok)
  sound: soundmo.enc (ok)
  theme: thememo.enc (ok)
  eva: evamo.enc (ok)
CryptoVisionLib_xp.dll hash verification passed.
CryptoVisionLib_xp.dll loaded (ffidl).
Crypto key test passed.
V2 salt: <64-hex salt>
Loading game rules...
>> rulesmo.enc (decrypted)
>> aimo.enc (decrypted)
>> artmo.enc (decrypted)
>> soundmo.enc (decrypted)
>> thememo.enc (decrypted)
>> evamo.enc (decrypted)
Loaded 1153 resources from audio_ra2.enc (decrypted)
Loaded 2285 resources from audio_yr.enc (decrypted)
Loaded 4478 resources from audio.enc (decrypted)
Total unique audio resources loaded: 6764

checking MAP: all01.map

Running AI cross-checks...
Log saved to: <project dir>/mission.log

>> Validation completed with errors.
```

Run with `--format json` to write `mission.log` as JSON, then
`third_party\json_report\json_report.exe mission.log` renders it as a standalone HTML report
(summary cards, severity filter chips, live search; `-o out.html` picks the
output path, `-open` launches the browser). The utility is 32-bit and runs
on Windows XP (PE32, subsystem 5.1, no ucrt).

### Run with specific options

```bash
tclsh86.exe main.tcl --batch *.map
```

### Interactive launcher

Double-click `__mission.bat` for an interactive menu.

### Built executables (build.bat)

`build.bat` builds three variants; each executable is self-contained in its own
folder (exe + its `settings.cfg` + its `.enc` set + DLL + helpers):

| Variant | Executable | Configuration | gamemode | Game / mod |
|---|---|---|---|---|
| **RA2MT** | `Build\RA2MT\RA2MT.exe` | `settings-ra2.cfg` | `ra2` | Red Alert 2 |
| **RA2YRMT** | `Build\RA2YRMT\RA2YRMT.exe` | `settings-yr.cfg` | `yr` | Red Alert 2: Yuri's Revenge |
| **MOMT** | `Build\MOMT\MOMT.exe` | `settings.cfg` | `ares` | Mental Omega (default) |

```bash
build.bat          # all three variants
build.bat ra2      # RA2MT only
build.bat yr       # RA2YRMT only
build.bat mo       # MOMT only
```

See [BUILD.md](BUILD.md) for the full build procedure (icons, version
resources, runtime files).

## Command-Line Options

```
┌────────────────────┬─────────────────────────────────────────────┐
│  OPTION            │  DESCRIPTION                                │
├────────────────────┼─────────────────────────────────────────────┤
│  <map_file>        │  Path to .map/.yrm/.mpr file to validate    │
│  --batch           │  Batch mode — validate multiple maps        │
│  --mode <name>     │  Game mode override: ra2/yr/ares/phobos     │
│  --salt <hex>      │  V2 decryption salt (64 hex chars)          │
│  --cfg <path>      │  Custom settings.cfg path                   │
│  --no-log-open     │  Don't auto-open log file after validation  │
│  --timing          │  Show processing time per phase             │
│  --quiet           │  Suppress console output (errors shown)     │
│  --format <fmt>    │  Report format: text (default), json        │
│  --baseline        │  Generate baseline.log from INI checks      │
│  --baseline-filter │  Suppress known warnings from baseline      │
│  --help            │  Show help                                  │
└────────────────────┴─────────────────────────────────────────────┘
```

## Configuration (settings.cfg)

Three configurations ship with the project. They share the same
`crypto_dll_expected_hash` and `v2_salt` and differ only in the rules files
and the game mode; at build time each variant gets its own copy as
`settings.cfg` next to its exe:

| File | Variant | Rules files | gamemode |
|---|---|---|---|
| `settings.cfg` | MOMT (default) | `rulesmo`, `aimo`, `artmo`, `soundmo`, `thememo`, `evamo` | `ares` |
| `settings-ra2.cfg` | RA2MT | `rules`, `ai`, `art`, `sound`, `theme`, `eva` | `ra2` |
| `settings-yr.cfg` | RA2YRMT | `rulesmd`, `aimd`, `artmd`, `soundmd`, `thememd`, `evamd` | `yr` |

The examples below show `settings.cfg` (MOMT).

### V2 Configuration (default)

```tcl
return [dict create \
    ra2dir "./" \
    ra2rul "rulesmo.enc" \
    ra2ai  "aimo.enc" \
    ra2art "artmo.enc" \
    ra2snd "soundmo.enc" \
    ra2tm  "thememo.enc" \
    ra2eva "evamo.enc" \
    gamemode "ares" \
    savelog 0 \
    writeanims 1 \
    showunused 1 \
    paranoid 1 \
    auto_open_log 1 \
    ini_encoding "" \
    sound_validation 1 \
    sound_check_audio 1 \
    sound_warn_unused 1 \
    sound_warn_duplicate_resources 0 \
    sound_warn_orphan_resources 1 \
    crypto_dll_expected_hash "e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f" \
    v2_salt "<64-hex salt>" \
]
```

### V1 Configuration (legacy)

For V1 encryption, leave `v2_salt` empty and use unencrypted `.enc` files:

```tcl
return [dict create \
    ra2dir "./" \
    ra2rul "rulesmo.enc" \
    ra2ai  "aimo.enc" \
    ra2art "artmo.enc" \
    ra2snd "soundmo.enc" \
    ra2tm  "thememo.enc" \
    ra2eva "evamo.enc" \
    gamemode "ares" \
    savelog 0 \
    writeanims 1 \
    showunused 1 \
    paranoid 1 \
    auto_open_log 1 \
    ini_encoding "" \
    sound_validation 1 \
    sound_check_audio 1 \
    sound_warn_unused 1 \
    sound_warn_duplicate_resources 0 \
    sound_warn_orphan_resources 1 \
    crypto_dll_expected_hash "e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f" \
    v2_salt "" \
]
```

### Key Settings Reference

```
┌────────────────────────────────┬─────────────────────────────────────┐
│  SETTING                       │  DESCRIPTION                        │
├────────────────────────────────┼─────────────────────────────────────┤
│  crypto_dll_expected_hash      │  SHA-256 of CryptoVisionLib_xp.dll  │
│  v2_salt                       │  Salt for V2 decryption (64 hex)    │
│  gamemode                      │  ra2 / yr / ares / phobos           │
│  sound_validation              │  Enable sound resource validation   │
│  ini_encoding                  │  Override INI encoding (or auto)    │
│  savelog                       │  Append to existing log file        │
│  writeanims                    │  Write animation log                │
│  showunused                    │  Show unused elements report        │
│  paranoid                      │  Extra strict validation            │
│  auto_open_log                 │  Auto-open log in editor            │
│  sound_check_audio             │  Check audio.idx resources          │
│  sound_warn_unused             │  Warn about unused sounds           │
│  sound_warn_duplicate_resources│  Warn about duplicate resources     │
│  sound_warn_orphan_resources   │  Warn about orphan resources        │
└────────────────────────────────┴─────────────────────────────────────┘
```

## Encryption

INI2MAP Tester uses **V2 multi-factor encryption** (default) or **V1 legacy encryption**.

### V2 Multi-Factor (current)

```
┌─────────────────────────────────────────────────────────────────┐
│  V2 KEY DERIVATION                                              │
│                                                                 │
│  ┌──────────────┐                                               │
│  │  DLL File    │──SHA-256──▶ [32B dll_hash]                    │
│  └──────────────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │  Salt        │──(32B random)──▶ [32B salt]                   │
│  └──────────────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  HKDF-SHA256                             │                   │
│  │  IKM = dll_hash                          │                   │
│  │  salt = salt                             │                   │
│  │  info = "CryptoVisionLib-v2-master-key"  │                   │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  [32B master_key]                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  Wrap random file key                    │                   │
│  │  random_key → XSalsa20+Poly1305 → wrapped│                   │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  Encrypted file format:                  │                   │
│  │  [CV02 magic 4B]                         │                   │
│  │  [wrapped_key 72B] (nonce24 + enc_key48) │                   │
│  │  [nonce 24B]                             │                   │
│  │  [ciphertext + MAC 16B]                  │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

Three factors required:
1. **DLL hash** — SHA-256 of CryptoVisionLib_xp.dll
2. **Salt** — random 32-byte value, shared separately
3. **Encrypted file** — contains wrapped random file key

### V1 Legacy

```
┌─────────────────────────────────────────────────────────────────┐
│  V1 KEY DERIVATION                                              │
│                                                                 │
│  ┌──────────────────────────────────────────┐                   │
│  │  DEFAULT_KEY[32] (hardcoded in DLL)      │                   │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  XSalsa20 + Poly1305 (NaCl secretbox)   │                    │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  Encrypted file format:                  │                   │
│  │  [nonce 24B]                             │                   │
│  │  [ciphertext + MAC 16B]                  │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

Single factor: DEFAULT_KEY embedded in DLL.

Auto-detected by presence of "CV02" magic bytes.

## Re-encrypting Files

If you need to change the encryption key or re-encrypt files, use `PatchDll.exe` and `crypto_utils.tcl`.

### Step 1: Generate new key (optional)

PatchDll generates a new random DEFAULT_KEY in the DLL:

```bash
PatchDll.exe CryptoVisionLib_xp.dll
```

**Output:**

```
Generated new random key: ec3fa41ed8762c7733845e2a957a6b2dd995a0d6f23751dafc947755db09e557
Successfully patched DEFAULT_KEY in CryptoVisionLib_xp.dll
New SHA-256 hash: e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f
Updated settings.cfg with the new hash.
```

### Step 2: Generate V2 salt (optional)

```bash
PatchDll.exe --v2 CryptoVisionLib_xp.dll
```

**Output:**

```
DLL SHA-256: e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f
Generated salt: <64-hex salt>

To encrypt files with this salt:
  tclsh crypto_utils.tcl --salt <64-hex salt> <files...>

To use in INI2MAP Tester:
  tclsh main.tcl --salt <64-hex salt> <map_file>

IMPORTANT: Keep this salt secret! Share it only with trusted users.
```

### Step 3: Update settings.cfg

Update `crypto_dll_expected_hash` and `v2_salt` in settings.cfg with the values from steps 1-2.

### Step 4: Encrypt .ini files

**Batch mode (recommended)** — encrypts everything in `original_files/`
and its subfolders (18 `.ini` + 6 `.idx`, 24 files) and writes the `.enc`
files into the project root:

```bash
tclsh86.exe crypto_utils.tcl --encrypt-originals --dry-run   # preview: what would be written
tclsh86.exe crypto_utils.tcl --encrypt-originals             # write .enc to the project root
tclsh86.exe crypto_utils.tcl --encrypt-originals --out temp\enc   # write to a relative subfolder
```

The salt is read from `settings.cfg` (`v2_salt`); override with `--salt <hex>`.
`CryptoVisionLib_xp.dll` is verified against `crypto_dll_expected_hash` first
(`--force` to skip that check). The command exits `0` only if every file
succeeded.

**Manual mode** — encrypt files one by one:

```bash
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/rulesmo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/aimo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/artmo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/soundmo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/thememo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/evamo.ini"
```

Each command writes `<base>_enc<ext>` next to the input file (`original_files/Mental Omega/rulesmo.ini` -> `original_files/Mental Omega/rulesmo_enc.ini`); only `--encrypt-originals` writes `<base>.enc` into the project root.

### Step 5: Encrypt .idx files

Audio index files must also be encrypted:

```bash
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/audio_ra2.idx"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/audio_yr.idx"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/audio.idx"
```

### Step 6: Copy DLL

Copy the patched `CryptoVisionLib_xp.dll` into the project root (run the command from there):

```bash
copy /Y CryptoVisionLib_xp.dll .
```

## Decrypting Files

To decrypt a V2 .enc file back to plaintext:

```bash
tclsh86.exe crypto_utils.tcl --salt <salt_hex> rulesmo.enc
```

**Output:**

```
CryptoVisionLib version: 2.0.0
Key is valid
DLL SHA-256: e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f
Encrypting (v2): rulesmo.enc -> rulesmo_dec.ini
  OK
```

Produces `rulesmo_dec.ini` in the current directory.

To decrypt a V1 .enc file:

```bash
tclsh86.exe crypto_utils.tcl rulesmo.enc
```

## Adding New Maps

1. Place `.map`, `.yrm`, or `.mpr` files in the MAP directory
2. Run validation:
   ```bash
   tclsh86.exe main.tcl your_map.map
   ```
3. Check `mission.log` for errors and warnings

## Batch Mode

Validate multiple maps at once:

```bash
tclsh86.exe main.tcl --batch *.map --format json
```

**Example JSON output:**

```json
{
  "total_maps": 3,
  "total_errors": 946,
  "total_warnings": 1367,
  "total_notices": 2207,
  "results": [
    {"map": "all01.map", "status": "error", "errors": 308, "warnings": 434, "notices": 701},
    {"map": "sov01.map", "status": "error", "errors": 305, "warnings": 420, "notices": 709},
    {"map": "TEST.map", "status": "error", "errors": 333, "warnings": 513, "notices": 797}
  ]
}
```

## Troubleshooting

```
┌─────────────────────────────────────────────────────────────────┐
│  FATAL: CryptoVisionLib_xp.dll hash mismatch!                   │
├─────────────────────────────────────────────────────────────────┤
│  The DLL has been modified or replaced.                         │
│  Fix: Update crypto_dll_expected_hash in settings.cfg           │
│                                                                 │
│  $ PatchDll.exe CryptoVisionLib_xp.dll                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  FATAL: V2 encrypted file detected but no salt provided         │
│  (pass --salt or provide settings.cfg): <file>                  │
├─────────────────────────────────────────────────────────────────┤
│  Fix: Set v2_salt in settings.cfg or pass --salt <hex>          │
│                                                                 │
│  $ tclsh86.exe main.tcl --salt <64-hex salt> your_map.map       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  FATAL: Cannot load Ffidl from ffidl_xp.dll: <error>            │
├─────────────────────────────────────────────────────────────────┤
│  Fix: Ensure ffidl_xp.dll is in the project root or             │
│  others/ffidl/ directory                                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  FATAL: sha256 package not available.                           │
├─────────────────────────────────────────────────────────────────┤
│  Fix: Ensure others/sha256/ directory exists                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  FATAL: Crypto key validation failed!                           │
├─────────────────────────────────────────────────────────────────┤
│  The DEFAULT_KEY in the DLL is corrupted or wrong.              │
│  Fix: Re-patch the DLL                                          │
│                                                                 │
│  $ PatchDll.exe CryptoVisionLib_xp.dll                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  WARNING: No audio index files could be loaded.                 │
│  Sound resource validation will be skipped.                     │
├─────────────────────────────────────────────────────────────────┤
│  Check that audio_ra2.enc, audio_yr.enc, audio.enc exist        │
│  and are encrypted with the correct salt.                       │
└─────────────────────────────────────────────────────────────────┘
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        INI2MAP Tester                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  main.tcl ──────────────────────────────────────────────────┐   │
│      │                                                      │   │
│      ├── cli.tcl ──────────── Parse arguments               │   │
│      │                                                      │   │
│      ├── config.tcl ───────── Load settings.cfg             │   │
│      │                                                      │   │
│      ├── crypto.tcl ───────── Init ffidl, load DLL,         │   │
│      │                       verify hash                    │   │
│      │                                                      │   │
│      ├── cache.tcl ────────── Rules/audio cache (batch)     │   │
│      │                                                      │   │
│      ├── utils.tcl ────────── Shared utility procs          │   │
│      │                                                      │   │
│      └── orchestrator.tcl ─── Main validation pipeline      │   │
│              │                                              │   │
│              ├── rules_parser.tcl + rules_parser/           │   │
│              │   └── Decrypt + parse .enc files             │   │
│              │                                              │   │
│              ├── taglist/                                   │   │
│              │   └── Validate tag names                     │   │
│              │                                              │   │
│              ├── audio_parser.tcl                           │   │
│              │   └── Decrypt + parse audio .enc files       │   │
│              │                                              │   │
│              ├── map_parser.tcl + map_parser/               │   │
│              │   └── Parse .map/.yrm/.mpr files             │   │
│              │                                              │   │
│              ├── validators.tcl + validators/               │   │
│              │   └── Validate triggers/events/actions       │   │
│              │                                              │   │
│              ├── checks.tcl + checks/                       │   │
│              │   └── 124 structural checks                  │   │
│              │                                              │   │
│              └── aicheck/                                   │   │
│                  └── AI cross-checks                        │   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Validation Checks

Every finding is reported at one of three severity levels. The process exit
code reflects the worst level found:

| Level | Meaning | Exit code |
|---|---|---|
| `ERROR` | The map will crash, corrupt data or fail to load in-game | **2** |
| `WARNING` | Known game bug or unsupported configuration | **1** |
| `NOTICE` | Suspicious pattern worth reviewing (may be intentional) | does not affect the exit code |

`0` = no errors/warnings, `1` = warnings only, `2` = errors present, `3` = fatal error (unhandled exception or crypto initialization failure).
CLI and configuration failures also exit with `1`.

### Where checks run

| Stage | Modules | Validates |
|---|---|---|
| Rules INI | `rules_parser.tcl` + `rules_parser/` (8 files) | Decryption and structure of `.enc` INI files |
| Audio | `audio_parser.tcl` | Audio index decryption and cross-references |
| Map file | `map_parser.tcl` + `map_parser/` (10 files) | Every map section: syntax, field counts, placement, houses, waypoints, tags, tubes, triggers |
| Integrity | `validators.tcl` + `validators/` (9 files) | Trigger enable/disable graph, events/actions/scripts, TaskForce/TeamType links, unused-object report |
| Rules cross-checks | `checks.tcl` + `checks/` (124 modules) | RA2/YR rule validation, grouped below |
| AI cross-checks | `aicheck/` (5 modules) | AI prerequisites, references, art, colors, voxels |
| Tags | `taglist/` | Tag name formats and sections |

### Map-integrity checks (reimplemented from WAE)

26 checks reimplemented from the [WAE](https://github.com/CnCNet/WorldAlteringEditor) (World Altering Editor) reference implementation (*MapLoader* /
*MapIssueChecker*):

| What it catches | Level | Module |
|---|---|---|
| Trigger with 0 events (never fires) or 0 actions (does nothing) | notice | `validators/trigger_integrity.tcl` |
| Trigger starts disabled and is never enabled by another trigger | notice | `validators/trigger_integrity.tcl` |
| Trigger is enabled by another trigger but never disabled | notice | `validators/trigger_integrity.tcl` |
| Trigger enables itself | notice | `validators/trigger_integrity.tcl` |
| LinkedTrigger chain loops back to the trigger itself (game crash) | notice | `validators/trigger_integrity.tcl` |
| `[Basic] Player=` house is missing or not PlayerControlled | notice | `map_parser/basic_map.tcl` |
| Trigger owner references a nonexistent HouseType | warning | `map_parser/team_script_taskforce_triggers.tcl` |
| Trigger declaration with fewer than 8 fields | warning | `map_parser/team_script_taskforce_triggers.tcl` |
| Trigger with more than 18 actions (game parsing buffer) | notice | `map_parser/team_script_taskforce_triggers.tcl` |
| Script with more than 50 actions | notice | `validators/scripts.tcl` |
| Enable/disable pair with mismatched difficulty levels | notice | `validators/trigger_integrity.tcl` |
| Two houses with the same ININame (corrupted house list) | notice | `map_parser/houses_countries.tcl` |
| House `Allies=` names a house that does not exist | warning | `map_parser/houses_countries.tcl` |
| Map-defined House without `Country=` | warning | `map_parser/houses_countries.tcl` |
| `[AITriggerTypes]` entry with a field count other than 18 | warning | `map_parser/aitriggers.tcl` |
| Unit `FOLLOWS_INDEX`: self-follow, invalid follower, duplicate followers | notice | `map_parser/structures_units_infantry.tcl` |
| Two infantry units on the same sub-cell | warning | `map_parser/structures_units_infantry.tcl` |
| Building upgrades applied in the map, `PowersUpBuilding` conflicts, too many upgrades | warning | `map_parser/structures_units_infantry.tcl` |
| `[VariableNames]`: invalid or duplicate local variable index | warning | `map_parser/houses_countries.tcl` |
| Malformed `[Tubes]` entry (fields, coordinates, facing) | warning | `checks/tubes_limit.tcl` |
| Smudge placed outside the usable map area | warning | `map_parser/celltags_house_data.tcl` |
| Waypoint index that is not a non-negative integer | warning | `map_parser/houses_countries.tcl` |
| Action whose fixed P1 differs from the documented value (WAE TriggerFix, modenc table) | notice | `validators/actions.tcl` |
| Building Exists event (32) the trigger house can never satisfy: no preplaced structure, no base node and no deployer unit/TeamType (WAE MapIssueChecker, single-player AI houses only) | notice | `validators/events.tcl` |
| `[Aircraft]` entry: too few fields, undefined type, bad house or tag | error | `map_parser/structures_units_infantry.tcl` |
| Event that must be attached ("Entered by…", "Bridge destroyed", local cell events) with nothing attached | notice | `validators/trigger_integrity.tcl` |

Numeric waypoint ranges are enforced as parse-time errors by `num2wp`
(`map_parser/core.tcl`; limits 25/702 hardcoded there, the `MAX_WAYPOINTS_*`
values in `constants.tcl` are only used by `report_unused.tcl`).

Not reimplemented from WAE: the cell/tile-based checks `ImpassableTile` and
`TiberiumUnsupportedRamp` (*MapIssueChecker*) and the `PostCheckMap`
terrain validation (*MapLoader*). They need the decoded `IsoMapPack5`
terrain and the overlay data, and the loader deliberately skips binary
sections (`binary_sections` in `map_parser/load_map.tcl`: `IsoMapPack5`,
`OverlayDataPack`, `OverlayPack`, `Preview`, `PreviewPack`,
`SpecialFlags`) so that multi-MB payloads never reach the parser.

### Rules checks (`checks/`, 124 modules)

Each module validates the decrypted rules INI against known game bugs and
documents its rule and references in the file header. Level tags:
**E** = error, **W** = warning, **N** = notice.

**Map structure & placement (3)** — map dimensions, tube and terrain limits:
`map` (E/W/N) · `terrain_foundation` (E) · `tubes_limit` (E/W)

**Triggers, TeamTypes & TaskForces (5)** — duplicates and broken team configs:
`aggressive_transport_teams` (W) · `suicide_aircraft` (W) · `taskforce_duplicates` (E) · `transports_return_bug` (W) · `veteran_level_reinforcement` (N)

**Buildings & base (25)** — building flag conflicts, prerequisites, docks, upgrades:
`armory` (E/W/N) · `bunker` (W/N) · `cloning` (E) · `cloning_facility` (W) · `construction_yard` (E) · `distributed_fire` (W/N) · `free_unit` (W) · `gap_radius_in_cells` (W) · `hospital` (W) · `laser_fence` (W) · `laser_fence_post` (W/N) · `number_of_docks` (W) · `pad_aircraft` (W) · `powers_unit` (W) · `prerequisite_override` (W) · `repairable` (W) · `requires_stolen_tech` (W/N) · `secret_lab_bonus_count` (W) · `secret_lab_techlevel_m1` (W) · `super_gap_radius` (W) · `turret_occupy` (W) · `turret_voxel_newtheater` (W) · `unit_absorb_dock_unload` (W) · `unit_repair_building` (W/N) · `weapons_factory_building` (W)

**Aircraft (6)** — docking, strafing and crash-related aircraft bugs:
`airport_bound` (W) · `balloon_hover` (W/N) · `carryall` (W/N) · `fire_once_aircraft` (E) · `rot_aircraft` (W) · `strafing_burst` (N)

**Units, infantry & vehicles (40)** — TechnoType flags, limits and Ares/Phobos option sanity:
`airstrike` (E/W) · `attach_effects` (W) · `crashable` (W/N) · `crew_flags` (E/W) · `damage_particle_systems_infantry` (W) · `deployed_crushable` (W) · `dont_score` (W) · `fraidycat` (W) · `guard_range` (W) · `gunner` (W) · `ifv_weapon_system` (E/W/N) · `infantry_flags` (E/W) · `insignificant` (W/N) · `invisible_in_game` (W) · `is_gattling` (W) · `is_simple_deployer` (W/N) · `land_targeting` (W) · `locomotor_bugs` (E/W) · `missile_spawn` (W) · `no_spawn_alt` (E/W) · `omni_crusher` (W) · `open_topped` (W) · `powered_unit` (W) · `primary_none_secondary` (W) · `sensors_sight` (W) · `sight_limit` (W/N) · `size_limit` (W/N) · `slowdown_distance` (W) · `speed_limit` (W/N) · `spray_attack` (W) · `strength_zero` (W) · `thief_guard_mode` (W) · `trainable_agent` (W/N) · `turret_count_weapon_count` (E/W) · `undeploys_into` (W/N) · `unit_crate_type_base_unit` (W) · `vehicle_unloading_water` (N) · `walk_rate_zero` (E) · `warpable_temporal` (W) · `weaponx_ifv` (W)

**Weapons & warheads (21)** — weapon/warhead flags and parameters that crash or break damage logic:
`affects_allies` (W) · `animlist_negative_damage` (W) · `areafire` (W) · `cell_spread` (E) · `cloak_stop` (W) · `culling` (W) · `direct_rocker` (W) · `infinite_mind_control` (W) · `is_laser` (W) · `is_locomotor` (W/N) · `is_sonic` (W) · `laser_parameters` (N) · `laser_thickness` (W) · `limbo_launch` (W) · `mind_control` (W) · `minimum_range` (W) · `nuke_maker` (W) · `range_weapon` (W/N) · `sonic_mindcontrol` (W) · `spawner_spawns` (E) · `temporal_particle` (W/N)

**Projectiles (6)** — projectile flags with engine limits or known bugs:
`ag_projectile` (W) · `airburst_split` (E/W) · `cluster` (W) · `inviso` (W) · `splits_limit` (N) · `vertical_projectile` (E/W)

**Animations, particles & terrain (7)** — animation/particle references and values:
`dig` (E/W) · `is_animated` (W) · `light_size` (E) · `next_particle` (W) · `share_source` (W) · `state_ai_advance` (W/N) · `wind_effect_particles` (E)

**Global rules & sections (7)** — `[General]`, `[AudioVisual]`, `[Countries]` and section-level overrides:
`armor_types` (E/W/N) · `attacking_aircraft_sight_range` (E/W) · `curley_shuffle` (W) · `selfheal_frames` (E/W) · `shake_screen` (E/W) · `speed_aircraft_mult` (W) · `verses_map_override` (N)

**SuperWeapons (4)** — SW type references and usage:
`auxbuilding_superweapons` (W) · `spysat_bugs` (W/N) · `use_charge_drain_superweapon` (W) · `weapontype_superweapon` (W)

### AI cross-checks (`aicheck/`, 5 modules)

`ref_check` (E/W/N) cross-references weapons, warheads, projectiles and
animations; `prereq_check` (W) validates building prerequisites and TechLevels;
`art_check` (W) validates ART data; `color_check` (W/N) validates the
`[Colors]` section; `voxel_check` (W/N) validates VoxelAnim properties.

## Test Coverage

```
┌─────────────────────────────────────────────────────────────────┐
│  TEST SUITE: 1124 tests across 131 test files                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ████████████████████████████████████████████████████ 100%      │
│  All tests passing                                              │
│                                                                 │
│  Core modules:                                                  │
│  test_constants.tcl .............. 25/25  ✅                    │
│  test_map_parser.tcl ............. 54/54  ✅                    │
│  test_map_parser_wae.tcl ......... 98/98  ✅                    │
│  test_fuzz_parser.tcl ............. 210/210  ✅                 │
│  test_trigger_integrity_wae.tcl ....... 23/23  ✅               │
│  test_checks_helpers.tcl ......... 34/34  ✅                    │
│  test_checks.tcl ................. 21/21  ✅                    │
│  test_aicheck.tcl ................ 19/19  ✅                    │
│  test_rules_parser.tcl ........... 20/20  ✅                    │
│  test_audio_parser.tcl ...........  8/8   ✅                    │
│  test_crypto_source_preserved.tcl   4/4   ✅                    │
│  test_taglist_attacheffect.tcl ....................... 10/10  ✅│
│  test_taglist_regex.tcl .......... 18/18  ✅                    │
│  test_taglist_section.tcl .........  7/7  ✅                    │
│  test_validators_core.tcl ......... 86/86  ✅                   │
│  test_trigger_integrity.tcl .......  8/8   ✅                   │
│  test_report_unused.tcl ........... 14/14  ✅                   │
│  test_report_unused_extended.tcl ... 9/9   ✅                   │
│  test_logging.tcl ................. 15/15  ✅                   │
│  test_cli.tcl ..................... 20/20  ✅                   │
│  test_config.tcl .................. 10/10  ✅                   │
│  test_orchestrator.tcl ............ 10/10  ✅                   │
│  test_crypto_utils_cli.tcl .........  6/6   ✅                  │
│                                                                 │
│  Plus 108 individual check test files (395 additional tests)    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

Run the whole suite with the bundled runner:

```console
tclsh86 tests/run_all.tcl             # all test files
tclsh86 tests/run_all.tcl -v          # print output of every test file
tclsh86 tests/run_all.tcl -k crypto   # only files whose name contains "crypto"
```

Exit code is `0` only when every test file passes.

The slow gates are deliberately separate from `run_all.tcl` (minutes, not seconds):

```console
tclsh86 tests/run_e2e.tcl             # E2E: 3 control maps vs numeric baselines
tclsh86 tests/run_e2e.tcl -exe        # post-build smoke through Build\MOMT\MOMT.exe
tclsh86 tests/fuzz_maps.tcl           # mutated control maps through the full CLI
```

`run_e2e.tcl` compares Errors/Warnings/Notices counts and the exit code of
`sov01.map`, `TEST.map` and `all01.map` against numeric baselines — numbers are
intentional, they also catch checks that silently disappear; update the table in
`tests/run_e2e.tcl` consciously when findings change. `fuzz_maps.tcl` mutates
`TEST.map` deterministically (fixed LCG seed, `-s` to reproduce, `-n` count) and
asserts only the process-level invariant: exit code in `0..2` with no unhandled
exception; failing mutants are kept with their `mission.log` in
`tests/_fuzz_maps/` (outside `tests/_tmp`, which `run_all` wipes after a green
run). The fast `tests/test_fuzz_parser.tcl` (inside `run_all`) fuzzes the
parser and the event/action validators with deterministic garbage inputs.

The whole verification stack (README boxes, INI2MAP-Tester.vfs mirror sync + MD5, unit
tests; `-E2E` adds both slow gates, `-Fuzz` the map fuzzer) is bundled in one
script:

```console
powershell -File tools\verify_all.ps1          # fast: boxes + sync + run_all
powershell -File tools\verify_all.ps1 -E2E     # + run_e2e + MOMT.exe smoke
powershell -File tools\verify_all.ps1 -Fuzz    # + slow map fuzzing
```

Individual steps: `tools\check_boxes.py`, `tools\sync_vfs.ps1` (step-0 whitelist
parsed from `build.bat` so the two cannot drift apart), `tools\run_one.ps1`
(timing of a single map run).

## License

```
┌─────────────────────────────────────────────────────────────────┐
│  LICENSE: CC BY-NC-SA 4.0                                       │
│  AUTHOR: YoWassup                                               │
│                                                                 │
│  https://creativecommons.org/licenses/by-nc-sa/4.0/             │
│                                                                 │
│  ✓ Attribution — You must give appropriate credit               │
│  ✓ NonCommercial — You may not use the material for commercial  │
│  ✓ ShareAlike — If you remix, transform, or build upon the      │
│    material, you must distribute your contributions under the   │
│    same license as the original.                                │
└─────────────────────────────────────────────────────────────────┘
```

## Credits

### Starting Projects

Based on analysis and adaptation of these RA2/YR modding tools:

| Project | Author | Description | Link |
|---------|--------|-------------|------|
| **AICheck** | G-E | Extensive rules/art/ai ini analysis | [PPM Forums](https://ppmforums.com/topic-68095/aicheck-a-script-for-extensively-analyzing-rulesartaiini/?highlight=AICHECK) |
| **SoundCheck** | G-E | Sound-related mistake checking | [PPM Forums](https://ppmforums.com/topic-68094/soundcheck-a-script-to-check-for-mistakes-related-to-sounds-in-rulesartsoundini/?highlight=SOUNDCHECK) |
| **MisTest** | G-E | Mission map code testing | [PPM Forums](https://ppmforums.com/topic-68090/mistest-a-script-to-test-mission-map-code-and-check-map-objects-for-errors/?highlight=MISTEST) |
| **TagList** | G-E | Tag validity checking in rules.ini | [PPM Forums](https://ppmforums.com/topic-68088/taglist-a-script-to-check-validity-of-tags-within-rulesini/?highlight=TAGLIST) |
| **WAE** | CnCNet | World Altering Editor — MapLoader/MapIssueChecker error handlers + 26 map-integrity checks reimplemented | [GitHub](https://github.com/CnCNet/WorldAlteringEditor) |

### Resources

Documentation used for game mechanics reference:

| Resource | Description | Link |
|----------|-------------|------|
| **Ares Docs** | Ares mod extension documentation | [ares-developers.github.io](https://ares-developers.github.io/Ares-docs/index.html#) |
| **Phobos Docs** | Phobos mod extension documentation | [phobos.readthedocs.io](https://phobos.readthedocs.io/en/latest/) |
| **MODENC** | RA2/YR INI tag reference | [modenc.renegadeprojects.com](https://modenc.renegadeprojects.com/Main_Page) |

### Technologies

| Technology | Purpose | License |
|------------|---------|---------|
| **Tcl 8.6** | Scripting language | Tcl License |
| **ffidl 0.9** | Tcl FFI to native libraries | BSD |
| **libsodium** | Cryptography (NaCl) | ISC License |
| **CryptoVisionLib** | Custom encryption DLL | CC BY-NC-SA 4.0 |
