<p align="center">
  <h1 align="center">INI2MAP Tester</h1>
  <p align="center">用于 Command & Conquer Red Alert 2 / Yuri's Revenge 模组制作的地图校验工具</p>
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
  <b>解密 • 解析 • 验证 • 报告</b>
</p>

---

## 功能特性

```
┌─────────────────────────────────────────────────────────────────┐
│  🔐 加密                                                        │
│  ├── V2 多因子：DLL 哈希 + 盐值 + HKDF-SHA256                   │
│  ├── V1 传统：DEFAULT_KEY（XSalsa20 + Poly1305）                │
│  └── 通过 "CV02" 魔数字节自动检测                               │
├─────────────────────────────────────────────────────────────────┤
│  📁 文件支持                                                    │
│  ├── 地图：.map、.yrm、.mpr                                     │
│  ├── 规则：.enc（加密 INI）                                     │
│  └── 音频：.enc（加密 .idx）                                    │
├─────────────────────────────────────────────────────────────────┤
│  ✅ 验证                                                        │
│  ├── 124 项结构检查（武器、弹头、动画）                         │
│  ├── AI 交叉检查（前置条件、引用、颜色）                        │
│  ├── 26 项 WAE 地图检查 + 触发器完整性                          │
│  ├── 音频资源校验                                               │
│  └── 批处理模式，附 JSON 汇总                                   │
├─────────────────────────────────────────────────────────────────┤
│  🎮 游戏模式                                                    │
│  ├── RA2（红色警戒 2）                                          │
│  ├── YR（尤里的复仇）                                           │
│  ├── Ares（模组扩展）                                           │
│  └── Phobos（模组扩展）                                         │
└─────────────────────────────────────────────────────────────────┘
```

## 环境要求

```
┌─────────────────────────────────────────────────────────────────┐
│  前置条件                                                       │
│                                                                 │
│  ✓ ActiveTcl 8.6（32 位）                                       │
│    └── tclsh86.exe 必须位于 PATH 或直接启动                     │
│                                                                 │
│  ✓ ffidl_xp.dll（兼容 XP 的 FFI，自包含）                       │
│    └── 位于 others/ffidl/                                       │
│                                                                 │
│  ✓ CryptoVisionLib_xp.dll（兼容 XP，静态链接）                  │
│    └── 位于 third_party/CryptoVisionLib/                        │
│                                                                 │
│  ○ PatchDll.exe（可选）                                         │
│    └── 仅在重新生成加密密钥时需要                               │
└─────────────────────────────────────────────────────────────────┘
```

## 文件结构

```
<project dir>\
│
├── 📄 main.tcl                  入口点
├── 📄 __mission.bat             交互式启动器
├── 📄 settings.cfg              配置 MOMT（哈希、盐值、游戏模式）
├── 📄 settings-ra2.cfg          配置 RA2MT（相同哈希/盐值，RA2 文件）
├── 📄 settings-yr.cfg           配置 RA2YRMT（相同哈希/盐值，YR 文件）
├── 🎨 MOMT.ico                  应用图标（MOMT 构建）
├── 🎨 RA2MT.ico                 应用图标（RA2MT 构建）
├── 🎨 RA2YRMT.ico               应用图标（RA2YRMT 构建）
│
├── 📁 original_files/           用于重新加密的原始明文文件
│   ├── Mental Omega/            9 个文件：rulesmo、aimo、artmo、soundmo、thememo、evamo、audio*
│   ├── Red Alert 2/             7 个文件：rules、ai、art、sound、theme、eva、audio_ra2
│   └── Red Alert 2 Yuris Revenge/  8 个文件：rulesmd、aimd、artmd、soundmd、thememd、evamd、audio*
│
├── 🔒 rulesmo.enc               MOMT 规则集（rulesmo、aimo、artmo、soundmo、thememo、evamo）
├── 🔒 rules.enc                 RA2MT 规则集（rules、ai、art、sound、theme、eva）
├── 🔒 rulesmd.enc               RA2YRMT 规则集（rulesmd、aimd、artmd、soundmd、thememd、evamd）
├── 🔒 audio_ra2.enc             音频索引（audio_ra2、audio_yr、audio - 所有变体共用）
│
├── 📄 crypto.tcl                加密模块（ffidl + DLL 集成）
├── 📄 crypto_utils.tcl          独立加解密工具
├── 📄 cli.tcl                   命令行参数解析器
├── 📄 config.tcl                配置加载器
├── 📄 constants.tcl             游戏常量
├── 📄 data.tcl                  全局数据数组
├── 📄 logging.tcl               日志写入器
├── 📄 orchestrator.tcl          主校验编排器
├── 📄 cache.tcl                 批处理模式的规则/音频缓存
├── 📄 utils.tcl                 共享工具过程
├── 📄 audio_parser.tcl          音频索引解析器（在内存中解密 .enc）
├── 📄 rules_parser.tcl          规则 INI 解析器
├── 📁 rules_parser/             规则解析器子模块（8 个文件）
├── 📄 map_parser.tcl            地图文件解析器
├── 📁 map_parser/               地图解析器子模块（10 个文件）
├── 📄 validators.tcl            校验器分发器
├── 📁 validators/               校验器模块（9 个文件）
├── 📄 checks.tcl                检查分发器 + 索引构建器
├── 📁 checks/                   检查模块（125 个文件：124 个模块 + 加载器）
├── 📁 aicheck/                  AI 交叉检查模块（7 个文件：5 个模块 + aicheck.tcl + core.tcl）
├── 📁 taglist/                  标签校验配置
├── 📁 others/                   外部依赖
│   ├── ffidl/                   ffidl FFI 包（ffidl_xp.dll + pkgIndex.tcl）
│   └── sha256/                  Tcl 的 SHA-256 包
├── 📁 third_party/              第三方源码与构建脚本
│   ├── CryptoVisionLib/         加密 DLL 源码 + build_xp.bat
│   ├── ffidl/                   ffidl 源码 + build_xp.bat
│   ├── json_report/             JSON 日志 -> HTML 报告源码 + build_xp.bat
│   ├── patch_key/               PatchDll 源码 + build_xp.bat
│   └── tag_reference/           Tag Reference 工作簿 + generate_tags.ps1
├── 📁 tools/                    构建二进制与校验脚本（sync/verify/check/run_one）
├── 📁 tests/                    测试文件（131 个文件，1124 个测试）
└── 📁 Build/                    构建出的自包含可执行文件（build.bat）
    ├── RA2MT/                   RA2MT.exe + settings.cfg + 自己的 .enc 集 + DLL 与辅助文件
    ├── RA2YRMT/                 RA2YRMT.exe + settings.cfg + 自己的 .enc 集 + DLL 与辅助文件
    └── MOMT/                    MOMT.exe + settings.cfg + 自己的 .enc 集 + DLL 与辅助文件
```

## 快速开始

### 对单张地图运行校验

```bash
cd /d <project dir>
tclsh86.exe main.tcl all01.map
```

如果 `tclsh86` 不在 PATH 中，请显式指定解释器路径（其余路径保持相对）：

```bash
"path\to\tclsh86.exe" main.tcl all01.map
```

**输出示例：**

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

使用 `--format json` 可将 `mission.log` 写为 JSON，随后
`third_party\json_report\json_report.exe mission.log` 会把它渲染为独立的 HTML 报告
（汇总卡片、严重级别筛选按钮、实时搜索；`-o out.html` 指定输出路径，
`-open` 启动浏览器）。该工具为 32 位，可在 Windows XP 上运行
（PE32、subsystem 5.1、无 ucrt）。

### 使用特定选项运行

```bash
tclsh86.exe main.tcl --batch *.map
```

### 交互式启动器

双击 `__mission.bat` 打开交互式菜单。

### 构建出的可执行文件（build.bat）

`build.bat` 构建三个变体；每个可执行文件在自己的文件夹中自包含
（exe + 自己的 `settings.cfg` + 自己的 `.enc` 集 + DLL + 辅助文件）：

| 变体 | 可执行文件 | 配置 | gamemode | 游戏 / 模组 |
|---|---|---|---|---|
| **RA2MT** | `Build\RA2MT\RA2MT.exe` | `settings-ra2.cfg` | `ra2` | Red Alert 2 |
| **RA2YRMT** | `Build\RA2YRMT\RA2YRMT.exe` | `settings-yr.cfg` | `yr` | Red Alert 2: Yuri's Revenge |
| **MOMT** | `Build\MOMT\MOMT.exe` | `settings.cfg` | `ares` | Mental Omega（默认） |

```bash
build.bat          # 构建全部三个变体
build.bat ra2      # 仅 RA2MT
build.bat yr       # 仅 RA2YRMT
build.bat mo       # 仅 MOMT
```

完整构建过程（图标、版本资源、运行时文件）见 [BUILD.zh.md](BUILD.zh.md)。

## 命令行选项

```
┌────────────────────┬─────────────────────────────────────────────┐
│  选项              │  说明                                       │
├────────────────────┼─────────────────────────────────────────────┤
│  <map_file>        │  要校验的 .map/.yrm/.mpr 文件路径           │
│  --batch           │  批处理模式 —— 校验多张地图                 │
│  --mode <name>     │  覆盖游戏模式：ra2/yr/ares/phobos           │
│  --salt <hex>      │  V2 解密盐值（64 个十六进制字符）           │
│  --cfg <path>      │  自定义 settings.cfg 路径                   │
│  --no-log-open     │  校验后不自动打开日志文件                   │
│  --timing          │  显示各阶段处理耗时                         │
│  --quiet           │  隐藏控制台输出（仍显示错误）               │
│  --format <fmt>    │  报告格式：text（默认）、json               │
│  --baseline        │  由 INI 检查生成 baseline.log               │
│  --baseline-filter │  按基线抑制已知警告                         │
│  --help            │  显示帮助                                   │
└────────────────────┴─────────────────────────────────────────────┘
```

## 配置（settings.cfg）

项目附带三个配置。它们的 `crypto_dll_expected_hash` 和 `v2_salt` 相同，
只在规则文件和游戏模式上不同；构建时每个变体都会得到自己的副本，
作为 `settings.cfg` 放在其 exe 旁：

| 文件 | 变体 | 规则文件 | gamemode |
|---|---|---|---|
| `settings.cfg` | MOMT（默认） | `rulesmo`、`aimo`、`artmo`、`soundmo`、`thememo`、`evamo` | `ares` |
| `settings-ra2.cfg` | RA2MT | `rules`、`ai`、`art`、`sound`、`theme`、`eva` | `ra2` |
| `settings-yr.cfg` | RA2YRMT | `rulesmd`、`aimd`、`artmd`、`soundmd`、`thememd`、`evamd` | `yr` |

下面的示例展示的是 `settings.cfg`（MOMT）。

### V2 配置（默认）

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

### V1 配置（传统）

对于 V1 加密，请将 `v2_salt` 留空，并使用未加密的 `.enc` 文件：

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

### 关键设置参考

```
┌────────────────────────────────┬─────────────────────────────────────┐
│  设置                          │  说明                               │
├────────────────────────────────┼─────────────────────────────────────┤
│  crypto_dll_expected_hash      │  CryptoVisionLib_xp.dll 的 SHA-256  │
│  v2_salt                       │  V2 解密盐值（64 位十六进制）       │
│  gamemode                      │  ra2 / yr / ares / phobos           │
│  sound_validation              │  启用音频资源校验                   │
│  ini_encoding                  │  覆盖 INI 编码（或自动）            │
│  savelog                       │  追加写入已有日志文件               │
│  writeanims                    │  写入动画日志                       │
│  showunused                    │  显示未使用元素报告                 │
│  paranoid                      │  超严格校验                         │
│  auto_open_log                 │  在编辑器中自动打开日志             │
│  sound_check_audio             │  检查 audio.idx 资源                │
│  sound_warn_unused             │  对未使用的声音告警                 │
│  sound_warn_duplicate_resources│  对重复资源告警                     │
│  sound_warn_orphan_resources   │  对孤立资源告警                     │
└────────────────────────────────┴─────────────────────────────────────┘
```

## 加密

INI2MAP Tester 使用 **V2 多因子加密**（默认）或 **V1 传统加密**。

### V2 多因子（当前）

```
┌─────────────────────────────────────────────────────────────────┐
│  V2 密钥派生                                                    │
│                                                                 │
│  ┌──────────────┐                                               │
│  │  DLL 文件    │──SHA-256──▶ [32B dll_hash]                    │
│  └──────────────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │  盐值        │──(32B random)──▶ [32B salt]                   │
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
│  │  包装随机文件密钥                        │                   │
│  │  random_key → XSalsa20+Poly1305 → wrapped│                   │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  加密文件格式：                          │                   │
│  │  [CV02 magic 4B]                         │                   │
│  │  [wrapped_key 72B] (nonce24 + enc_key48) │                   │
│  │  [nonce 24B]                             │                   │
│  │  [ciphertext + MAC 16B]                  │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

需要三个因子：
1. **DLL 哈希** — CryptoVisionLib_xp.dll 的 SHA-256
2. **盐值** — 随机 32 字节值，另行共享
3. **加密文件** — 包含被包装的随机文件密钥

### V1 传统

```
┌─────────────────────────────────────────────────────────────────┐
│  V1 密钥派生                                                    │
│                                                                 │
│  ┌──────────────────────────────────────────┐                   │
│  │  DEFAULT_KEY[32]（硬编码于 DLL）         │                   │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  XSalsa20 + Poly1305 (NaCl secretbox)   │                    │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  加密文件格式：                          │                   │
│  │  [nonce 24B]                             │                   │
│  │  [ciphertext + MAC 16B]                  │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

单一因子：内嵌于 DLL 中的 DEFAULT_KEY。

通过 "CV02" 魔数字节自动检测。

## 重新加密文件

如需更换加密密钥或重新加密文件，请使用 `PatchDll.exe` 和 `crypto_utils.tcl`。

### 步骤 1：生成新密钥（可选）

PatchDll 在 DLL 中生成新的随机 DEFAULT_KEY：

```bash
PatchDll.exe CryptoVisionLib_xp.dll
```

**输出：**

```
Generated new random key: ec3fa41ed8762c7733845e2a957a6b2dd995a0d6f23751dafc947755db09e557
Successfully patched DEFAULT_KEY in CryptoVisionLib_xp.dll
New SHA-256 hash: e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f
Updated settings.cfg with the new hash.
```

### 步骤 2：生成 V2 盐值（可选）

```bash
PatchDll.exe --v2 CryptoVisionLib_xp.dll
```

**输出：**

```
DLL SHA-256: e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f
Generated salt: <64-hex salt>

To encrypt files with this salt:
  tclsh crypto_utils.tcl --salt <64-hex salt> <files...>

To use in INI2MAP Tester:
  tclsh main.tcl --salt <64-hex salt> <map_file>

IMPORTANT: Keep this salt secret! Share it only with trusted users.
```

### 步骤 3：更新 settings.cfg

用步骤 1-2 得到的值更新 settings.cfg 中的 `crypto_dll_expected_hash` 和 `v2_salt`。

### 步骤 4：加密 .ini 文件

**批处理模式（推荐）** — 加密 `original_files/` 及其子文件夹中的全部文件
（18 个 `.ini` + 6 个 `.idx`，共 24 个文件），并把 `.enc` 写入项目根目录：

```bash
tclsh86.exe crypto_utils.tcl --encrypt-originals --dry-run   # preview: what would be written
tclsh86.exe crypto_utils.tcl --encrypt-originals             # write .enc to the project root
tclsh86.exe crypto_utils.tcl --encrypt-originals --out temp\enc   # write to a relative subfolder
```

盐值从 `settings.cfg`（`v2_salt`）读取；可用 `--salt <hex>` 覆盖。
`CryptoVisionLib_xp.dll` 会先按 `crypto_dll_expected_hash` 校验
（`--force` 可跳过该检查）。只有当全部文件都成功时，命令才以 `0` 退出。

**手动模式** — 逐个加密文件：

```bash
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/rulesmo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/aimo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/artmo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/soundmo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/thememo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/evamo.ini"
```

每条命令都会在输入文件旁生成 `<base>_enc<ext>`（如 `original_files/Mental Omega/rulesmo.ini` -> `original_files/Mental Omega/rulesmo_enc.ini`）；只有 `--encrypt-originals` 才会把 `<base>.enc` 写入项目根目录。

### 步骤 5：加密 .idx 文件

音频索引文件同样必须加密：

```bash
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/audio_ra2.idx"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/audio_yr.idx"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/audio.idx"
```

### 步骤 6：复制 DLL

把打好补丁的 `CryptoVisionLib_xp.dll` 复制到项目根目录（请在根目录执行该命令）：

```bash
copy /Y CryptoVisionLib_xp.dll .
```

## 解密文件

将 V2 的 .enc 文件解密回明文：

```bash
tclsh86.exe crypto_utils.tcl --salt <salt_hex> rulesmo.enc
```

**输出：**

```
CryptoVisionLib version: 2.0.0
Key is valid
DLL SHA-256: e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f
Encrypting (v2): rulesmo.enc -> rulesmo_dec.ini
  OK
```

在当前目录生成 `rulesmo_dec.ini`。

解密 V1 的 .enc 文件：

```bash
tclsh86.exe crypto_utils.tcl rulesmo.enc
```

## 添加新地图

1. 将 `.map`、`.yrm` 或 `.mpr` 文件放入 MAP 目录
2. 运行校验：
   ```bash
   tclsh86.exe main.tcl your_map.map
   ```
3. 查看 `mission.log` 中的错误与警告

## 批处理模式

一次校验多张地图：

```bash
tclsh86.exe main.tcl --batch *.map --format json
```

**JSON 输出示例：**

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

## 故障排查

```
┌─────────────────────────────────────────────────────────────────┐
│  致命错误: CryptoVisionLib_xp.dll hash mismatch!                │
├─────────────────────────────────────────────────────────────────┤
│  The DLL has been modified or replaced.                         │
│  修复: Update crypto_dll_expected_hash in settings.cfg          │
│                                                                 │
│  $ PatchDll.exe CryptoVisionLib_xp.dll                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  致命错误: V2 encrypted file detected but no salt provided      │
│  (pass --salt or provide settings.cfg): <file>                  │
├─────────────────────────────────────────────────────────────────┤
│  修复: Set v2_salt in settings.cfg or pass --salt <hex>         │
│                                                                 │
│  $ tclsh86.exe main.tcl --salt <64-hex salt> your_map.map       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  致命错误: Cannot load Ffidl from ffidl_xp.dll: <error>         │
├─────────────────────────────────────────────────────────────────┤
│  修复: Ensure ffidl_xp.dll is in the project root or            │
│  others/ffidl/ directory                                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  致命错误: sha256 package not available.                        │
├─────────────────────────────────────────────────────────────────┤
│  修复: Ensure others/sha256/ directory exists                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  致命错误: Crypto key validation failed!                        │
├─────────────────────────────────────────────────────────────────┤
│  The DEFAULT_KEY in the DLL is corrupted or wrong.              │
│  修复: Re-patch the DLL                                         │
│                                                                 │
│  $ PatchDll.exe CryptoVisionLib_xp.dll                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  警告: No audio index files could be loaded.                    │
│  Sound resource validation will be skipped.                     │
├─────────────────────────────────────────────────────────────────┤
│  Check that audio_ra2.enc, audio_yr.enc, audio.enc exist        │
│  and are encrypted with the correct salt.                       │
└─────────────────────────────────────────────────────────────────┘
```

## 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        INI2MAP Tester                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  main.tcl ──────────────────────────────────────────────────┐   │
│      │                                                      │   │
│      ├── cli.tcl ──────────── 解析参数                      │   │
│      │                                                      │   │
│      ├── config.tcl ───────── 加载 settings.cfg             │   │
│      │                                                      │   │
│      ├── crypto.tcl ───────── 初始化 ffidl，加载 DLL，      │   │
│      │                       校验哈希                       │   │
│      │                                                      │   │
│      ├── cache.tcl ────────── 规则/音频缓存（批处理）       │   │
│      │                                                      │   │
│      ├── utils.tcl ────────── 共享工具过程                  │   │
│      │                                                      │   │
│      └── orchestrator.tcl ─── 主校验流水线                  │   │
│              │                                              │   │
│              ├── rules_parser.tcl + rules_parser/           │   │
│              │   └── 解密并解析 .enc 文件                   │   │
│              │                                              │   │
│              ├── taglist/                                   │   │
│              │   └── 验证标签名称                           │   │
│              │                                              │   │
│              ├── audio_parser.tcl                           │   │
│              │   └── 解密并解析音频 .enc 文件               │   │
│              │                                              │   │
│              ├── map_parser.tcl + map_parser/               │   │
│              │   └── 解析 .map/.yrm/.mpr 文件               │   │
│              │                                              │   │
│              ├── validators.tcl + validators/               │   │
│              │   └── 验证触发器/事件/动作                   │   │
│              │                                              │   │
│              ├── checks.tcl + checks/                       │   │
│              │   └── 124 项结构检查                         │   │
│              │                                              │   │
│              └── aicheck/                                   │   │
│                  └── AI 交叉检查                            │   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 验证检查

每条问题都以三个严重级别之一报告。进程退出码反映所发现的最严重级别：

| 级别 | 含义 | 退出码 |
|---|---|---|
| `ERROR` | 地图会崩溃、损坏数据或在游戏中无法加载 | **2** |
| `WARNING` | 已知的游戏 Bug 或不受支持的配置 | **1** |
| `NOTICE` | 值得复查的可疑模式（可能是有意为之） | 不影响退出码 |

`0` = 无错误/警告，`1` = 仅有警告，`2` = 存在错误，`3` = 致命错误（未处理的异常或加密模块初始化失败）。
命令行与配置失败同样以 `1` 退出。

### 检查执行阶段

| 阶段 | 模块 | 校验内容 |
|---|---|---|
| 规则 INI | `rules_parser.tcl` + `rules_parser/`（8 个文件） | `.enc` INI 文件的解密与结构 |
| 音频 | `audio_parser.tcl` | 音频索引解密与交叉引用 |
| 地图文件 | `map_parser.tcl` + `map_parser/`（10 个文件） | 每个地图节：语法、字段数、摆放、阵营、路径点、标签、管道、触发器 |
| 完整性 | `validators.tcl` + `validators/`（9 个文件） | 触发器启用/禁用图、事件/动作/脚本、TaskForce/TeamType 关联、未使用对象报告 |
| 规则交叉检查 | `checks.tcl` + `checks/`（124 个模块） | RA2/YR 规则校验，分组见下 |
| AI 交叉检查 | `aicheck/`（5 个模块） | AI 前置条件、引用、美术、颜色、体素 |
| 标签 | `taglist/` | 标签名称格式与节 |

### 地图完整性检查（根据 WAE 重新实现）

26 项检查根据 [WAE](https://github.com/CnCNet/WorldAlteringEditor)（World Altering Editor）参考实现重新实现（*MapLoader* /
*MapIssueChecker*）：

| 捕获的问题 | 级别 | 模块 |
|---|---|---|
| 0 个事件的触发器（永不触发）或 0 个动作的触发器（什么都不做） | notice | `validators/trigger_integrity.tcl` |
| 触发器初始为禁用状态，且从不被其他触发器启用 | notice | `validators/trigger_integrity.tcl` |
| 触发器被其他触发器启用，但从不被禁用 | notice | `validators/trigger_integrity.tcl` |
| 触发器启用自身 | notice | `validators/trigger_integrity.tcl` |
| LinkedTrigger 链回绕到触发器自身（游戏崩溃） | notice | `validators/trigger_integrity.tcl` |
| `[Basic] Player=` 阵营缺失或不是 PlayerControlled | notice | `map_parser/basic_map.tcl` |
| 触发器所有者引用了不存在的 HouseType | warning | `map_parser/team_script_taskforce_triggers.tcl` |
| 触发器声明的字段少于 8 个 | warning | `map_parser/team_script_taskforce_triggers.tcl` |
| 动作超过 18 个的触发器（游戏解析缓冲区） | notice | `map_parser/team_script_taskforce_triggers.tcl` |
| 动作超过 50 个的脚本 | notice | `validators/scripts.tcl` |
| 启用/禁用对的难度级别不匹配 | notice | `validators/trigger_integrity.tcl` |
| 两个阵营拥有相同 ININame（阵营列表损坏） | notice | `map_parser/houses_countries.tcl` |
| 阵营 `Allies=` 指向不存在的阵营 | warning | `map_parser/houses_countries.tcl` |
| 地图定义的阵营缺少 `Country=` | warning | `map_parser/houses_countries.tcl` |
| `[AITriggerTypes]` 条目的字段数不是 18 | warning | `map_parser/aitriggers.tcl` |
| 单位 `FOLLOWS_INDEX`：自我跟随、无效跟随者、重复跟随者 | notice | `map_parser/structures_units_infantry.tcl` |
| 两个步兵单位位于同一子格 | warning | `map_parser/structures_units_infantry.tcl` |
| 地图中应用的建筑升级、`PowersUpBuilding` 冲突、升级过多 | warning | `map_parser/structures_units_infantry.tcl` |
| `[VariableNames]`：无效或重复的局部变量索引 | warning | `map_parser/houses_countries.tcl` |
| `[Tubes]` 条目格式错误（字段、坐标、朝向） | warning | `checks/tubes_limit.tcl` |
| 涂鸦（Smudge）放置在可用地图区域之外 | warning | `map_parser/celltags_house_data.tcl` |
| 路径点索引不是非负整数 | warning | `map_parser/houses_countries.tcl` |
| 固定 P1 与文档值不同的动作（WAE TriggerFix，modenc 表） | notice | `validators/actions.tcl` |
| 触发器阵营永远无法满足的 Building Exists 事件 (32)：无预置建筑、无基地节点、无可部署单位/TeamType（WAE MapIssueChecker，仅单人 AI 阵营） | notice | `validators/events.tcl` |
| `[Aircraft]` 条目：字段过少、未定义类型、阵营或标签错误 | error | `map_parser/structures_units_infantry.tcl` |
| 必须附加内容的事件（"Entered by…"、"Bridge destroyed"、本地格子事件）却没有附加任何内容 | notice | `validators/trigger_integrity.tcl` |

数值路径点范围在解析时即作为错误强制执行（`num2wp`，位于 `map_parser/core.tcl`；限制 25/702 硬编码于其中，`constants.tcl` 中的 `MAX_WAYPOINTS_*` 仅由 `report_unused.tcl` 使用）。

未根据 WAE 重新实现：基于格子/图块的检查 `ImpassableTile` 和
`TiberiumUnsupportedRamp`（*MapIssueChecker*）以及 `PostCheckMap`
地形校验（*MapLoader*）。它们需要解码后的 `IsoMapPack5` 地形与
覆盖层数据，而加载器有意跳过二进制节（`map_parser/load_map.tcl` 中的
`binary_sections`：`IsoMapPack5`、`OverlayDataPack`、`OverlayPack`、
`Preview`、`PreviewPack`、`SpecialFlags`），使数 MB 的负载永远不会
进入解析器。

### 规则检查（`checks/`，124 个模块）

每个模块将解密后的规则 INI 对照已知游戏 Bug 进行校验，并在文件头部
记录其规则与引用。级别标签：**E** = error，**W** = warning，**N** = notice。

**地图结构与摆放 (3)** — 地图尺寸、管道与地形限制：
`map` (E/W/N) · `terrain_foundation` (E) · `tubes_limit` (E/W)

**触发器、TeamType 与 TaskForce (5)** — 重复项与损坏的队伍配置：
`aggressive_transport_teams` (W) · `suicide_aircraft` (W) · `taskforce_duplicates` (E) · `transports_return_bug` (W) · `veteran_level_reinforcement` (N)

**建筑与基地 (25)** — 建筑标志冲突、前置条件、码头、升级：
`armory` (E/W/N) · `bunker` (W/N) · `cloning` (E) · `cloning_facility` (W) · `construction_yard` (E) · `distributed_fire` (W/N) · `free_unit` (W) · `gap_radius_in_cells` (W) · `hospital` (W) · `laser_fence` (W) · `laser_fence_post` (W/N) · `number_of_docks` (W) · `pad_aircraft` (W) · `powers_unit` (W) · `prerequisite_override` (W) · `repairable` (W) · `requires_stolen_tech` (W/N) · `secret_lab_bonus_count` (W) · `secret_lab_techlevel_m1` (W) · `super_gap_radius` (W) · `turret_occupy` (W) · `turret_voxel_newtheater` (W) · `unit_absorb_dock_unload` (W) · `unit_repair_building` (W/N) · `weapons_factory_building` (W)

**飞机 (6)** — 停靠、扫射与坠毁相关的飞机 Bug：
`airport_bound` (W) · `balloon_hover` (W/N) · `carryall` (W/N) · `fire_once_aircraft` (E) · `rot_aircraft` (W) · `strafing_burst` (N)

**单位、步兵与载具 (40)** — TechnoType 标志、限制以及 Ares/Phobos 选项合理性：
`airstrike` (E/W) · `attach_effects` (W) · `crashable` (W/N) · `crew_flags` (E/W) · `damage_particle_systems_infantry` (W) · `deployed_crushable` (W) · `dont_score` (W) · `fraidycat` (W) · `guard_range` (W) · `gunner` (W) · `ifv_weapon_system` (E/W/N) · `infantry_flags` (E/W) · `insignificant` (W/N) · `invisible_in_game` (W) · `is_gattling` (W) · `is_simple_deployer` (W/N) · `land_targeting` (W) · `locomotor_bugs` (E/W) · `missile_spawn` (W) · `no_spawn_alt` (E/W) · `omni_crusher` (W) · `open_topped` (W) · `powered_unit` (W) · `primary_none_secondary` (W) · `sensors_sight` (W) · `sight_limit` (W/N) · `size_limit` (W/N) · `slowdown_distance` (W) · `speed_limit` (W/N) · `spray_attack` (W) · `strength_zero` (W) · `thief_guard_mode` (W) · `trainable_agent` (W/N) · `turret_count_weapon_count` (E/W) · `undeploys_into` (W/N) · `unit_crate_type_base_unit` (W) · `vehicle_unloading_water` (N) · `walk_rate_zero` (E) · `warpable_temporal` (W) · `weaponx_ifv` (W)

**武器与弹头 (21)** — 会崩溃或破坏伤害逻辑的武器/弹头标志与参数：
`affects_allies` (W) · `animlist_negative_damage` (W) · `areafire` (W) · `cell_spread` (E) · `cloak_stop` (W) · `culling` (W) · `direct_rocker` (W) · `infinite_mind_control` (W) · `is_laser` (W) · `is_locomotor` (W/N) · `is_sonic` (W) · `laser_parameters` (N) · `laser_thickness` (W) · `limbo_launch` (W) · `mind_control` (W) · `minimum_range` (W) · `nuke_maker` (W) · `range_weapon` (W/N) · `sonic_mindcontrol` (W) · `spawner_spawns` (E) · `temporal_particle` (W/N)

**抛射物 (6)** — 存在引擎限制或已知 Bug 的抛射物标志：
`ag_projectile` (W) · `airburst_split` (E/W) · `cluster` (W) · `inviso` (W) · `splits_limit` (N) · `vertical_projectile` (E/W)

**动画、粒子与地形 (7)** — 动画/粒子引用与数值：
`dig` (E/W) · `is_animated` (W) · `light_size` (E) · `next_particle` (W) · `share_source` (W) · `state_ai_advance` (W/N) · `wind_effect_particles` (E)

**全局规则与节 (7)** — `[General]`、`[AudioVisual]`、`[Countries]` 以及节级覆盖：
`armor_types` (E/W/N) · `attacking_aircraft_sight_range` (E/W) · `curley_shuffle` (W) · `selfheal_frames` (E/W) · `shake_screen` (E/W) · `speed_aircraft_mult` (W) · `verses_map_override` (N)

**超级武器 (4)** — SW 类型引用与用法：
`auxbuilding_superweapons` (W) · `spysat_bugs` (W/N) · `use_charge_drain_superweapon` (W) · `weapontype_superweapon` (W)

### AI 交叉检查（`aicheck/`，5 个模块）

`ref_check` (E/W/N) 交叉引用武器、弹头、抛射物与动画；
`prereq_check` (W) 校验建筑前置条件与 TechLevel；
`art_check` (W) 校验 ART 数据；`color_check` (W/N) 校验
`[Colors]` 节；`voxel_check` (W/N) 校验 VoxelAnim 属性。

## 测试覆盖

```
┌─────────────────────────────────────────────────────────────────┐
│  测试套件：131 个测试文件，共 1124 项测试                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ████████████████████████████████████████████████████ 100%      │
│  全部测试通过                                                   │
│                                                                 │
│  核心模块：                                                     │
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
│  另有 108 个独立检查测试文件（395 项额外测试）                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

使用自带的运行器运行整个测试套件：

```console
tclsh86 tests/run_all.tcl             # all test files
tclsh86 tests/run_all.tcl -v          # print output of every test file
tclsh86 tests/run_all.tcl -k crypto   # only files whose name contains "crypto"
```

仅当每个测试文件都通过时退出码才为 `0`。

慢速门禁有意与 `run_all.tcl` 分开（以分钟计，而非秒）：

```console
tclsh86 tests/run_e2e.tcl             # E2E: 3 control maps vs numeric baselines
tclsh86 tests/run_e2e.tcl -exe        # post-build smoke through Build\MOMT\MOMT.exe
tclsh86 tests/fuzz_maps.tcl           # mutated control maps through the full CLI
```

`run_e2e.tcl` 将 `sov01.map`、`TEST.map` 和 `all01.map` 的
Errors/Warnings/Notices 计数与退出码同数值基线对比——这些数字是
有意固定的，它们也能捕捉到悄悄消失的检查；当问题发生变化时，请
有意识地更新 `tests/run_e2e.tcl` 中的表格。`fuzz_maps.tcl` 以
确定性方式变异 `TEST.map`（固定 LCG 种子，`-s` 复现，`-n` 数量），
只断言进程级不变量：退出码位于 `0..2` 范围内且没有未处理的异常；
失败的变异体连同其 `mission.log` 保存在 `tests/_fuzz_maps/`
（位于 `tests/_tmp` 之外，`run_all` 全绿后会清空该目录）。快速的
`tests/test_fuzz_parser.tcl`（属于 `run_all`）用确定性的垃圾输入
对解析器和事件/动作校验器进行模糊测试。

整套验证流程（README 方框、INI2MAP-Tester.vfs 镜像同步 + MD5、单元测试；
`-E2E` 增加两个慢速门禁，`-Fuzz` 增加地图模糊测试）打包在一个
脚本中：

```console
powershell -File tools\verify_all.ps1          # fast: boxes + sync + run_all
powershell -File tools\verify_all.ps1 -E2E     # + run_e2e + MOMT.exe smoke
powershell -File tools\verify_all.ps1 -Fuzz    # + slow map fuzzing
```

各个步骤：`tools\check_boxes.py`、`tools\sync_vfs.ps1`（step-0 白名单
从 `build.bat` 解析，两者不会产生偏差）、`tools\run_one.ps1`
（单张地图运行计时）。

## 许可证

```
┌─────────────────────────────────────────────────────────────────┐
│  许可证: CC BY-NC-SA 4.0                                        │
│  作者: YoWassup                                                 │
│                                                                 │
│  https://creativecommons.org/licenses/by-nc-sa/4.0/             │
│                                                                 │
│  ✓ 署名 — 您必须给出适当的署名                                  │
│  ✓ 非商业 — 不得将本材料用于商业用途                            │
│  ✓ 相同方式共享 — 如果您对材料进行 remix、transform 或          │
│    二次创作，必须以与原作品相同的许可证分发您的                 │
│    贡献。                                                       │
└─────────────────────────────────────────────────────────────────┘
```

## 致谢

### 起始项目

基于对以下 RA2/YR 模组工具的分析与改编：

| 项目 | 作者 | 描述 | 链接 |
|---------|--------|-------------|------|
| **AICheck** | G-E | 广泛的规则/美术/ai ini 分析 | [PPM Forums](https://ppmforums.com/topic-68095/aicheck-a-script-for-extensively-analyzing-rulesartaiini/?highlight=AICHECK) |
| **SoundCheck** | G-E | 声音相关错误检查 | [PPM Forums](https://ppmforums.com/topic-68094/soundcheck-a-script-to-check-for-mistakes-related-to-sounds-in-rulesartsoundini/?highlight=SOUNDCHECK) |
| **MisTest** | G-E | 任务地图代码测试 | [PPM Forums](https://ppmforums.com/topic-68090/mistest-a-script-to-test-mission-map-code-and-check-map-objects-for-errors/?highlight=MISTEST) |
| **TagList** | G-E | rules.ini 中的标签有效性检查 | [PPM Forums](https://ppmforums.com/topic-68088/taglist-a-script-to-check-validity-of-tags-within-rulesini/?highlight=TAGLIST) |
| **WAE** | CnCNet | World Altering Editor — 重新实现了 MapLoader/MapIssueChecker 错误处理与 26 项地图完整性检查 | [GitHub](https://github.com/CnCNet/WorldAlteringEditor) |

### 资源

用于游戏机制参考的文档：

| 资源 | 描述 | 链接 |
|----------|-------------|------|
| **Ares Docs** | Ares 模组扩展文档 | [ares-developers.github.io](https://ares-developers.github.io/Ares-docs/index.html#) |
| **Phobos Docs** | Phobos 模组扩展文档 | [phobos.readthedocs.io](https://phobos.readthedocs.io/en/latest/) |
| **MODENC** | RA2/YR INI 标签参考 | [modenc.renegadeprojects.com](https://modenc.renegadeprojects.com/Main_Page) |

### 技术

| 技术 | 用途 | 许可证 |
|------------|---------|---------|
| **Tcl 8.6** | 脚本语言 | Tcl License |
| **ffidl 0.9** | Tcl 到本地库的 FFI | BSD |
| **libsodium** | 加密（NaCl） | ISC License |
| **CryptoVisionLib** | 自定义加密 DLL | CC BY-NC-SA 4.0 |
