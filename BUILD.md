# INI2MAP Tester — Build (RA2MT / RA2YRMT / MOMT)

**Documentation:** English · [Русский](BUILD.ru.md) · [中文](BUILD.zh.md)

## Build Variants

All three variants are built from one `INI2MAP-Tester.vfs` payload. Each variant is
self-contained in its own folder (`Build\<variant>\`): exe + its own
`settings.cfg` + its own `.enc` set + DLL + helpers. The exe name selects the
behavior: `main.tcl` and `crypto.tcl` recognize the starpack variants
`MOMT.exe` / `RA2MT.exe` / `RA2YRMT.exe` and resolve `settings.cfg`, `.enc`
and the DLL next to the exe.

| Variant | build.bat argument | Output | Configuration (gamemode) | Icon | Version resource |
|---|---|---|---|---|---|
| **RA2MT** — Red Alert 2 | `build.bat ra2` | `Build\RA2MT\RA2MT.exe` | `settings-ra2.cfg` (`ra2`) | `RA2MT.ico` | `tools\version_ra2.res` |
| **RA2YRMT** — Yuri's Revenge | `build.bat yr` | `Build\RA2YRMT\RA2YRMT.exe` | `settings-yr.cfg` (`yr`) | `RA2YRMT.ico` | `tools\version_ra2yr.res` |
| **MOMT** — Mental Omega (default) | `build.bat mo` | `Build\MOMT\MOMT.exe` | `settings.cfg` (`ares`) | `MOMT.ico` | `tools\version.res` |

`build.bat` with no arguments builds all three variants; an unknown argument
stops the build with `ERROR: unknown variant "<arg>"`.

### Encrypted resources per variant

| Variant | `.enc` files copied into its folder |
|---|---|
| RA2MT | `rules.enc`, `ai.enc`, `art.enc`, `sound.enc`, `theme.enc`, `eva.enc`, `audio_ra2.enc` |
| RA2YRMT | `rulesmd.enc`, `aimd.enc`, `artmd.enc`, `soundmd.enc`, `thememd.enc`, `evamd.enc`, `audio_ra2.enc`, `audio_yr.enc` |
| MOMT | `rulesmo.enc`, `aimo.enc`, `artmo.enc`, `soundmo.enc`, `thememo.enc`, `evamo.enc`, `audio.enc`, `audio_ra2.enc`, `audio_yr.enc` |

All `.enc` files are written into the project root by
`crypto_utils.tcl --encrypt-originals` (see README.md, Re-encrypting Files).
`build.bat` refuses to build a variant while any file of its set is missing.

## Required Tools

| Tool | Where to get | Purpose |
|---|---|---|
| **Tcl 8.6** | `C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe` | Tcl interpreter — runtime for the starpack and the sdx launcher |
| **sdx.kit** | https://chiselapp.com/user/aspect/repository/sdx/uv/sdx-20110317.kit (119 KB) | Starkit Extension eXtensions — packs the Tcl application into a starpack |
| **ResourceHacker** | Downloaded automatically from https://www.angusj.com/resourcehacker/ on the first build (version **5.x+** required; NuGet 4.7.34 does NOT work with the sdx starpack) | Embeds the icon and the version info into the PE |

### Required Files

| File | Purpose |
|---|---|
| `tools/base.exe` | Copy of `base-tcl8.6-thread-win32-ix86.exe` — runtime for the starpack |
| `tools/version.res` | Compiled version resource — MOMT |
| `tools/version_ra2.res` | Compiled version resource — RA2MT (InternalName `RA2MT`) |
| `tools/version_ra2yr.res` | Compiled version resource — RA2YRMT (InternalName `RA2YRMT`) |
| `MOMT.ico` | Application icon — MOMT |
| `RA2MT.ico` | Application icon — RA2MT |
| `RA2YRMT.ico` | Application icon — RA2YRMT |

### Runtime Files (project root, NOT packed into the exe)

| File | Purpose |
|---|---|
| `CryptoVisionLib_xp.dll` | Cryptographic library (NaCl/XSalsa20+Poly1305) |
| `settings.cfg` | MOMT configuration (Tcl dict format, gamemode `ares`) |
| `settings-ra2.cfg` | RA2MT configuration (gamemode `ra2`) |
| `settings-yr.cfg` | RA2YRMT configuration (gamemode `yr`) |
| `*.enc` | Encrypted resources — per-variant sets, see the table above |
| `tags-*.cfg` | Tag configurations for taglist (tags-ra2, tags-yr, tags-ares, tags-phobos, tags-ext). Generated from `third_party\tag_reference\tag_reference.xlsx`: `powershell -File third_party\tag_reference\generate_tags.ps1` |

## Build Procedure

### Automatic build (build.bat)

```
build.bat          # all three variants
build.bat ra2      # RA2MT only
build.bat yr       # RA2YRMT only
build.bat mo       # MOMT only
```

The script performs the following steps:

0. **Sync INI2MAP-Tester.vfs** — robocopy the source `.tcl` trees (`aicheck`, `checks`, `map_parser`, `rules_parser`, `validators`, `taglist`, `others`) and the root `.tcl` modules into `INI2MAP-Tester.vfs\lib\app-ini2map-tester\`, so the starpack matches the sources (build.bat step 0)
1. **Download ResourceHacker** — if `tools\ResourceHacker.exe` is missing, it is downloaded automatically from angusj.com
2. **Copy base.exe** — create a copy of the Tcl runtime (a running instance cannot be wrapped)
3. **sdx wrap** — pack `INI2MAP-Tester.vfs/` into a starpack (once, shared by all variants):
   ```
   base-tcl8.6-thread-win32-ix86.exe sdx.kit wrap INI2MAP-Tester -runtime base.exe
   ```
   sdx creates a file without an extension (`INI2MAP-Tester`); it is deleted after the variants are built
4. **Per variant** (`:build_variant ra2|yr|mo`) — for every selected variant:
   - verify that every `.enc` of the variant's set exists in the project root (otherwise: `BUILD FAILED: missing <file>`)
   - copy the wrapped kit to `Build\<variant>\<variant>.exe` (the exe name is what makes the starpack resolve its own runtime files)
   - remove the old resources and embed the variant's icon + version info via ResourceHacker:
     ```
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action delete -mask "ICONGROUP,," -log NUL
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action delete -mask "VERSION,," -log NUL
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action addoverwrite -resource "MOMT.ico" -mask "ICONGROUP,MAINICON," -log NUL
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action addoverwrite -resource "tools\version.res" -mask "VERSION,," -log NUL
     ```
     (RA2MT uses `RA2MT.ico` + `tools\version_ra2.res`, RA2YRMT uses `RA2YRMT.ico` + `tools\version_ra2yr.res`)
   - copy the runtime files into `Build\<variant>\`: `CryptoVisionLib_xp.dll`, the variant's own config as `settings.cfg`, its `.enc` set, `tags-*.cfg`, `sha256.tcl`, `ffidl_xp.dll`, the generated `pkgIndex.tcl`, `json_report.exe`
5. **Shared** — `json_report.exe` is copied into the project root (HTML report: `json_report mission.log`), `ffidl_xp.dll` too (for script mode)

### Manual build (step by step)

```bash
# 0. Sync INI2MAP-Tester.vfs with the sources (build.bat step 0: robocopy *.tcl into INI2MAP-Tester.vfs\lib\app-ini2map-tester\)

# 1. Copy base.exe
copy "C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe" "tools\base.exe"

# 2. Wrap into a starpack
"C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe" "tools\sdx.kit" wrap INI2MAP-Tester -runtime "tools\base.exe"

# 3. Per variant (example: MOMT)
mkdir Build\MOMT
copy INI2MAP-Tester Build\MOMT\MOMT.exe
del INI2MAP-Tester
# ... ResourceHacker commands from build.bat (MOMT.ico + tools\version.res)

# 4. Copy runtime files
copy CryptoVisionLib_xp.dll Build\MOMT\
copy settings.cfg Build\MOMT\settings.cfg
copy rulesmo.enc aimo.enc artmo.enc soundmo.enc thememo.enc evamo.enc audio.enc audio_ra2.enc audio_yr.enc Build\MOMT\
copy tags-*.cfg Build\MOMT\
copy others\sha256\sha256.tcl Build\MOMT\
copy others\ffidl\ffidl_xp.dll Build\MOMT\
copy third_party\json_report\json_report.exe json_report.exe
```

For RA2MT: `settings-ra2.cfg` -> `Build\RA2MT\settings.cfg` and the RA2 `.enc`
set; for RA2YRMT: `settings-yr.cfg` -> `Build\RA2YRMT\settings.cfg` and the
YR `.enc` sets (see the tables above).

## Project Structure

```
H:\MAP\
├── build.bat                    # Build script (build.bat [ra2|yr|mo])
├── main.tcl                     # Entry point (also INI2MAP-Tester.vfs/main.tcl as bootstrap)
├── crypto.tcl                   # Cryptography module (ffidl)
├── cli.tcl                      # CLI argument parser
├── config.tcl                   # Configuration loader
├── constants.tcl                # Constants
├── data.tcl                     # Global data
├── logging.tcl                  # Logging
├── orchestrator.tcl             # Check orchestration
├── cache.tcl                    # Rules/audio caching (batch mode)
├── utils.tcl                    # Shared utility procs
├── checks.tcl                   # Checks module
├── validators.tcl               # Trigger/script validators
├── rules_parser.tcl             # Rules INI parser
├── map_parser.tcl               # .map file parser
├── audio_parser.tcl             # Audio resource parser
├── crypto_utils.tcl             # Encrypt/decrypt utility
├── encrypt_v2.tcl               # V2 encryption
├── check_key.tcl                # Key check
├── reencrypt_all.tcl            # Re-encrypt all files
├── taglist/taglist.tcl          # Tag validation
├── checks/*.tcl                 # 124+ check modules
├── validators/*.tcl             # Validation modules
├── rules_parser/*.tcl           # Rules parser sub-modules
├── map_parser/*.tcl             # Map parser sub-modules
├── aicheck/*.tcl                # AI cross-checks
├── others/ffidl/                # ffidl package (ffidl_xp.dll + pkgIndex.tcl)
├── others/sha256/               # SHA-256 package
├── third_party/                 # Sources and build scripts
│   ├── CryptoVisionLib/         # Crypto DLL source + build_xp.bat
│   ├── ffidl/                   # ffidl source + build_xp.bat
│   ├── patch_key/               # PatchDll source + build_xp.bat
│   └── tag_reference/           # Tag Reference.xlsx, Regular_to_Excel.txt, generate_tags.ps1
├── CryptoVisionLib_xp.dll       # Cryptographic DLL
├── settings.cfg                 # MOMT configuration (gamemode ares)
├── settings-ra2.cfg             # RA2MT configuration (gamemode ra2)
├── settings-yr.cfg              # RA2YRMT configuration (gamemode yr)
├── tags-*.cfg                   # Tag configurations (tag generator see above)
├── *.enc                        # Encrypted resources (all three variant sets)
├── MOMT.ico                     # Icon (MOMT)
├── RA2MT.ico                    # Icon (RA2MT)
├── RA2YRMT.ico                  # Icon (RA2YRMT)
├── INI2MAP-Tester.vfs/                    # Source VFS for sdx wrap
│   ├── main.tcl                 # Bootstrap (source → lib/app-ini2map-tester/main.tcl)
│   └── lib/app-ini2map-tester/            # All .tcl files, others/, checks/, validators/...
├── tools/
│   ├── base.exe                 # Copy of the Tcl runtime
│   ├── sdx.kit                  # Starkit Extension eXtensions
│   ├── version.res              # Version resource (MOMT)
│   ├── version_ra2.res          # Version resource (RA2MT)
│   ├── version_ra2yr.res        # Version resource (RA2YRMT)
│   └── ResourceHacker.exe       # Downloaded from angusj.com on the first build
└── Build/
    ├── RA2MT/
    │   ├── RA2MT.exe            # Finished starpack (Red Alert 2)
    │   ├── settings.cfg         # = settings-ra2.cfg
    │   └── *.enc + DLL, tags-*.cfg, sha256.tcl, ffidl_xp.dll, pkgIndex.tcl, json_report.exe
    ├── RA2YRMT/
    │   ├── RA2YRMT.exe          # Finished starpack (Yuri's Revenge)
    │   ├── settings.cfg         # = settings-yr.cfg
    │   └── *.enc + DLL, tags-*.cfg, sha256.tcl, ffidl_xp.dll, pkgIndex.tcl, json_report.exe
    └── MOMT/
        ├── MOMT.exe             # Finished starpack (Mental Omega)
        ├── settings.cfg         # = settings.cfg
        └── *.enc + DLL, tags-*.cfg, sha256.tcl, ffidl_xp.dll, pkgIndex.tcl, json_report.exe
```

## Running

### Via a starpack (Build\<variant>\)
```
H:\MAP\Build\MOMT\MOMT.exe <map_file>
H:\MAP\Build\RA2MT\RA2MT.exe <map_file>
H:\MAP\Build\RA2YRMT\RA2YRMT.exe <map_file>

H:\MAP\Build\MOMT\MOMT.exe --baseline
H:\MAP\Build\MOMT\MOMT.exe --baseline-filter baseline.log <map_file>
H:\MAP\Build\MOMT\MOMT.exe --batch <pattern|directory>
```

### Via the scripts (sources)
```
C:\Tcl\bin\tclsh86.exe H:\MAP\main.tcl <map_file>
```

Interactive launcher: `__mission.bat`

## Notes

- **Exe name = variant.** `main.tcl` and `crypto.tcl` check the exe base name against `momt|ra2mt|ra2yrmt`: only then is `::app_dir` set to the exe's directory (runtime files next to the exe) and starpack detection enabled. Renaming the exe breaks runtime resolution.
- **sdx wrap** packs the files from `INI2MAP-Tester.vfs/` into a starpack. The VFS inside the exe: `main.tcl` (bootstrap) and `lib/app-ini2map-tester/` (all modules, including `cache.tcl`, `utils.tcl`). One wrap serves all three variants.
- **CryptoVisionLib_xp.dll** is not packed into the exe — it is looked up next to the exe (starpack) or next to the scripts (script mode). Resolved through `::app_dir` in main.tcl.
- **Runtime files** (DLL, .enc, .cfg) are copied into `Build\<variant>\` at build time; each starpack gets its own variant's files.
- **Version info** and the **icon** are embedded through ResourceHacker: `tools/version.res` (MOMT), `tools/version_ra2.res` (RA2MT), `tools/version_ra2yr.res` (RA2YRMT).
- **FileAlignment base kit** = 0x1000 (non-standard). BeginUpdateResource does not work. Use ResourceHacker only.
- **ffidl_xp.dll** — statically linked ffidl (no libffi dependencies), Windows XP compatible.
- **CryptoVisionLib_xp.dll** — statically linked crypto DLL (ADVAPI32+KERNEL32+msvcrt), Windows XP compatible.
- **third_party/** — source code and build scripts for the libraries (CryptoVisionLib, ffidl, patch_key, json_report, tag_reference).
