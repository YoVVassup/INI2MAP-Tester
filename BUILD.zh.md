# INI2MAP Tester — 构建（RA2MT / RA2YRMT / MOMT）

**文档：** [English](BUILD.md) · [Русский](BUILD.ru.md) · 中文

## 构建变体

三个变体都由同一个 `INI2MAP-Tester.vfs` 载荷构建。每个变体在自己的文件夹
（`Build\<变体>\`）中自包含：exe + 自己的 `settings.cfg` + 自己的 `.enc` 集
+ DLL + 辅助文件。行为由 exe 名称决定：`main.tcl` 和 `crypto.tcl` 识别
starpack 变体 `MOMT.exe` / `RA2MT.exe` / `RA2YRMT.exe`，并在 exe 旁解析
`settings.cfg`、`.enc` 和 DLL。

| 变体 | build.bat 参数 | 输出 | 配置（gamemode） | 图标 | 版本资源 |
|---|---|---|---|---|---|
| **RA2MT** — Red Alert 2 | `build.bat ra2` | `Build\RA2MT\RA2MT.exe` | `settings-ra2.cfg`（`ra2`） | `RA2MT.ico` | `tools\version_ra2.res` |
| **RA2YRMT** — Yuri's Revenge | `build.bat yr` | `Build\RA2YRMT\RA2YRMT.exe` | `settings-yr.cfg`（`yr`） | `RA2YRMT.ico` | `tools\version_ra2yr.res` |
| **MOMT** — Mental Omega（默认） | `build.bat mo` | `Build\MOMT\MOMT.exe` | `settings.cfg`（`ares`） | `MOMT.ico` | `tools\version.res` |

不带参数的 `build.bat` 构建全部三个变体；未知参数会以
`ERROR: unknown variant "<参数>"` 终止构建。

### 各变体的加密资源

| 变体 | 复制到其文件夹的 `.enc` 文件 |
|---|---|
| RA2MT | `rules.enc`、`ai.enc`、`art.enc`、`sound.enc`、`theme.enc`、`eva.enc`、`audio_ra2.enc` |
| RA2YRMT | `rulesmd.enc`、`aimd.enc`、`artmd.enc`、`soundmd.enc`、`thememd.enc`、`evamd.enc`、`audio_ra2.enc`、`audio_yr.enc` |
| MOMT | `rulesmo.enc`、`aimo.enc`、`artmo.enc`、`soundmo.enc`、`thememo.enc`、`evamo.enc`、`audio.enc`、`audio_ra2.enc`、`audio_yr.enc` |

`.enc` 集由维护者工具生成；构建前，变体集合中的每个文件都必须位于项目根目录。
缺少任一文件时 `build.bat` 拒绝构建该变体。

## 所需工具

| 工具 | 获取方式 | 用途 |
|---|---|---|
| **Tcl 8.6** | `C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe` | Tcl 解释器 — starpack 的运行时以及 sdx 的启动器 |
| **sdx.kit** | https://chiselapp.com/user/aspect/repository/sdx/uv/sdx-20110317.kit (119 KB) | Starkit Extension eXtensions — 将 Tcl 应用打包为 starpack |
| **ResourceHacker** | 首次构建时自动从 https://www.angusj.com/resourcehacker/ 下载（需要 **5.x+** 版本；NuGet 4.7.34 与 sdx starpack 不兼容） | 向 PE 中嵌入图标和版本信息 |

### 所需文件

| 文件 | 用途 |
|---|---|
| `tools/base.exe` | `base-tcl8.6-thread-win32-ix86.exe` 的副本 — starpack 的运行时 |
| `tools/version.res` | 已编译的版本资源 — MOMT |
| `tools/version_ra2.res` | 已编译的版本资源 — RA2MT（InternalName `RA2MT`） |
| `tools/version_ra2yr.res` | 已编译的版本资源 — RA2YRMT（InternalName `RA2YRMT`） |
| `MOMT.ico` | 应用程序图标 — MOMT |
| `RA2MT.ico` | 应用程序图标 — RA2MT |
| `RA2YRMT.ico` | 应用程序图标 — RA2YRMT |

### 运行时文件（位于项目根目录，不打包进 exe）

| 文件 | 用途 |
|---|---|
| `CryptoVisionLib_xp.dll` | 加密库（运行时库，需与 exe 同目录） |
| `settings.cfg` | MOMT 配置（Tcl dict 格式，gamemode `ares`） |
| `settings-ra2.cfg` | RA2MT 配置（gamemode `ra2`） |
| `settings-yr.cfg` | RA2YRMT 配置（gamemode `yr`） |
| `*.enc` | 加密资源 — 各变体的集合，见上表 |
| `tags-*.cfg` | taglist 的标签配置（tags-ra2、tags-yr、tags-ares、tags-phobos、tags-ext）。由 `third_party\tag_reference\tag_reference.xlsx` 生成：`powershell -File third_party\tag_reference\generate_tags.ps1` |

## 构建流程

### 自动构建（build.bat）

```
build.bat          # 全部三个变体
build.bat ra2      # 仅 RA2MT
build.bat yr       # 仅 RA2YRMT
build.bat mo       # 仅 MOMT
```

脚本执行以下步骤：

0. **同步 INI2MAP-Tester.vfs** — 将源码目录 `.tcl`（`aicheck`、`checks`、`map_parser`、`rules_parser`、`validators`、`taglist`、`others`）及根目录 `.tcl` 模块 robocopy 到 `INI2MAP-Tester.vfs\lib\app-ini2map-tester\`，使 starpack 与源码保持一致（build.bat 第 0 步）。vfs 每次构建都会从零重建，模块清单为白名单：`crypto_utils.tcl`、`check_key.tcl`、`encrypt_v2.tcl`、`reencrypt_all.tcl` 属于维护者工具，不会打包；若载荷或最终的 `Build\<variant>` 目录中出现 `*.ini`/`*.idx`、`tests/`、`original_files/`、`decrypt_helper.tcl`、`MAINTAINER.md` 或维护者模块，构建将中止
1. **下载 ResourceHacker** — 若 `tools\ResourceHacker.exe` 缺失，则自动从 angusj.com 下载
2. **复制 base.exe** — 创建 Tcl 运行时的副本（正在运行的实例无法被包装）
3. **sdx wrap** — 将 `INI2MAP-Tester.vfs/` 打包为 starpack（一次，所有变体共享）：
   ```
   base-tcl8.6-thread-win32-ix86.exe sdx.kit wrap INI2MAP-Tester -runtime base.exe
   ```
   sdx 生成的文件没有扩展名（`INI2MAP-Tester`）；各变体构建完成后会删除它
4. **逐变体处理**（`:build_variant ra2|yr|mo`），对每个选中的变体：
   - 检查该变体集合中的每个 `.enc` 是否存在于项目根目录（否则：`BUILD FAILED: missing <文件>`）
   - 将打包好的 kit 复制为 `Build\<变体>\<变体>.exe`（正是 exe 的名称让 starpack 解析自己的运行时文件）
   - 通过 ResourceHacker 删除旧资源并嵌入该变体的图标 + 版本信息：
     ```
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action delete -mask "ICONGROUP,," -log NUL
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action delete -mask "VERSION,," -log NUL
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action addoverwrite -resource "MOMT.ico" -mask "ICONGROUP,MAINICON," -log NUL
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action addoverwrite -resource "tools\version.res" -mask "VERSION,," -log NUL
     ```
     （RA2MT 使用 `RA2MT.ico` + `tools\version_ra2.res`，RA2YRMT 使用 `RA2YRMT.ico` + `tools\version_ra2yr.res`）
   - 将运行时文件复制到 `Build\<变体>\`：`CryptoVisionLib_xp.dll`、该变体自己的配置作为 `settings.cfg`、它的 `.enc` 集、`tags-*.cfg`、`sha256.tcl`、`ffidl_xp.dll`、生成的 `pkgIndex.tcl`、`json_report.exe`
5. **共享** — `json_report.exe` 复制到项目根目录（HTML 报告：`json_report mission.log`），`ffidl_xp.dll` 也一样（用于脚本模式）
6. **受保护资源** — `build.bat` 为每个变体写入携带本次构建密钥材料的运行时文件，
   并将其设为 hidden + system。若没有可用的密钥材料，构建以退出码 1 停止。

### 手动构建（分步）

```bash
# 0. 同步 INI2MAP-Tester.vfs 与源码（build.bat 第 0 步：robocopy *.tcl 到 INI2MAP-Tester.vfs\lib\app-ini2map-tester\）

# 1. 复制 base.exe
copy "C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe" "tools\base.exe"

# 2. 打包为 starpack
"C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe" "tools\sdx.kit" wrap INI2MAP-Tester -runtime "tools\base.exe"

# 3. 逐变体处理（示例：MOMT）
mkdir Build\MOMT
copy INI2MAP-Tester Build\MOMT\MOMT.exe
del INI2MAP-Tester
# ... build.bat 中的 ResourceHacker 命令（MOMT.ico + tools\version.res）

# 4. 复制运行时文件
copy CryptoVisionLib_xp.dll Build\MOMT\
copy settings.cfg Build\MOMT\settings.cfg
copy rulesmo.enc aimo.enc artmo.enc soundmo.enc thememo.enc evamo.enc audio.enc audio_ra2.enc audio_yr.enc Build\MOMT\
copy tags-*.cfg Build\MOMT\
copy others\sha256\sha256.tcl Build\MOMT\
copy others\ffidl\ffidl_xp.dll Build\MOMT\
copy third_party\json_report\json_report.exe json_report.exe
# 步骤 6（受保护资源）仅限维护者：请用 build.bat 生成可运行的变体
```

RA2MT：`settings-ra2.cfg` -> `Build\RA2MT\settings.cfg` 与 RA2 `.enc` 集；
RA2YRMT：`settings-yr.cfg` -> `Build\RA2YRMT\settings.cfg` 与 YR `.enc` 集
（见上表）。

## 项目结构

```
H:\MAP\
├── build.bat                    # 构建脚本（build.bat [ra2|yr|mo]）
├── main.tcl                     # 入口点（同时作为 INI2MAP-Tester.vfs/main.tcl 引导）
├── crypto.tcl                   # 加密模块（ffidl）
├── cli.tcl                      # 命令行参数解析器
├── config.tcl                   # 配置加载器
├── constants.tcl                # 常量
├── data.tcl                     # 全局数据
├── logging.tcl                  # 日志记录
├── orchestrator.tcl             # 检查任务编排
├── cache.tcl                    # 规则/音频缓存（批处理模式）
├── utils.tcl                    # 通用工具过程
├── checks.tcl                   # 检查模块
├── validators.tcl               # 触发器/脚本校验器
├── rules_parser.tcl             # 规则 INI 解析器
├── map_parser.tcl               # .map 文件解析器
├── audio_parser.tcl             # 音频资源解析器
├── crypto_utils.tcl             # 加密工具（维护者）
├── encrypt_v2.tcl               # V2 加密（维护者）
├── check_key.tcl                # 密钥检查（维护者）
├── reencrypt_all.tcl            # 重新加密工具（维护者）
├── taglist/taglist.tcl          # 标签校验
├── checks/*.tcl                 # 124+ 检查模块
├── validators/*.tcl             # 校验模块
├── rules_parser/*.tcl           # 规则解析器子模块
├── map_parser/*.tcl             # 地图解析器子模块
├── aicheck/*.tcl                # AI 交叉检查
├── others/ffidl/                # ffidl 包（ffidl_xp.dll + pkgIndex.tcl）
├── others/sha256/               # SHA-256 包
├── third_party/                 # 源码与构建脚本
│   ├── CryptoVisionLib/         # 加密 DLL 源码 + build_xp.bat
│   ├── ffidl/                   # ffidl 源码 + build_xp.bat
│   ├── patch_key/               # 维护者工具源码 + build_xp.bat
│   └── tag_reference/           # Tag Reference.xlsx、Regular_to_Excel.txt、generate_tags.ps1
├── CryptoVisionLib_xp.dll       # 加密 DLL
├── settings.cfg                 # MOMT 配置（gamemode ares）
├── settings-ra2.cfg             # RA2MT 配置（gamemode ra2）
├── settings-yr.cfg              # RA2YRMT 配置（gamemode yr）
├── tags-*.cfg                   # 标签配置（生成器见上文）
├── *.enc                        # 加密资源（三个变体的全部集合）
├── MOMT.ico                     # 图标（MOMT）
├── RA2MT.ico                    # 图标（RA2MT）
├── RA2YRMT.ico                  # 图标（RA2YRMT）
├── INI2MAP-Tester.vfs/                    # 用于 sdx wrap 的源 VFS
│   ├── main.tcl                 # 引导文件（source → lib/app-ini2map-tester/main.tcl）
│   └── lib/app-ini2map-tester/            # 全部 .tcl 文件、others/、checks/、validators/...
├── tools/
│   ├── base.exe                 # Tcl 运行时副本
│   ├── sdx.kit                  # Starkit Extension eXtensions
│   ├── version.res              # 版本资源（MOMT）
│   ├── version_ra2.res          # 版本资源（RA2MT）
│   ├── version_ra2yr.res        # 版本资源（RA2YRMT）
│   └── ResourceHacker.exe       # 首次构建时从 angusj.com 下载
└── Build/
    ├── RA2MT/
    │   ├── RA2MT.exe            # 生成的 starpack（Red Alert 2）
    │   ├── settings.cfg         # = settings-ra2.cfg
    │   └── *.enc + DLL、tags-*.cfg、sha256.tcl、ffidl_xp.dll、pkgIndex.tcl、json_report.exe
    ├── RA2YRMT/
    │   ├── RA2YRMT.exe          # 生成的 starpack（Yuri's Revenge）
    │   ├── settings.cfg         # = settings-yr.cfg
    │   └── *.enc + DLL、tags-*.cfg、sha256.tcl、ffidl_xp.dll、pkgIndex.tcl、json_report.exe
    └── MOMT/
        ├── MOMT.exe             # 生成的 starpack（Mental Omega）
        ├── settings.cfg         # = settings.cfg
        └── *.enc + DLL、tags-*.cfg、sha256.tcl、ffidl_xp.dll、pkgIndex.tcl、json_report.exe
```

## 运行

### 通过 starpack（Build\<变体>\）
```
H:\MAP\Build\MOMT\MOMT.exe <map_file>
H:\MAP\Build\RA2MT\RA2MT.exe <map_file>
H:\MAP\Build\RA2YRMT\RA2YRMT.exe <map_file>

H:\MAP\Build\MOMT\MOMT.exe --baseline
H:\MAP\Build\MOMT\MOMT.exe --baseline-filter baseline.log <map_file>
H:\MAP\Build\MOMT\MOMT.exe --batch <pattern|directory>
```

### 通过脚本（源码）
```
C:\Tcl\bin\tclsh86.exe H:\MAP\main.tcl <map_file>
```

交互式启动：`__mission.bat`

## 备注

- **exe 名称 = 变体。** `main.tcl` 和 `crypto.tcl` 将 exe 基名与列表 `momt|ra2mt|ra2yrmt` 比对：只有匹配时 `::app_dir` 才设为 exe 所在目录（运行时文件在 exe 旁），并启用 starpack 检测。重命名 exe 会破坏运行时解析。
- **sdx wrap** 将 `INI2MAP-Tester.vfs/` 中的文件打包为 starpack。exe 内部的 VFS：`main.tcl`（引导）和 `lib/app-ini2map-tester/`（全部模块，包括 `cache.tcl`、`utils.tcl`）。一次打包服务三个变体。
- **CryptoVisionLib_xp.dll** 不打包进 exe — 在 exe 旁（starpack）或脚本旁（脚本模式）查找。通过 main.tcl 中的 `::app_dir` 解析。
- **运行时文件**（DLL、.enc、.cfg）在构建时复制到 `Build\<变体>\`；每个 starpack 得到自己变体的文件。
- **版本信息**和**图标**通过 ResourceHacker 嵌入：`tools/version.res`（MOMT）、`tools/version_ra2.res`（RA2MT）、`tools/version_ra2yr.res`（RA2YRMT）。
- **FileAlignment base kit** = 0x1000（非标准）。BeginUpdateResource 不可用，请只使用 ResourceHacker。
- **ffidl_xp.dll** — 静态链接的 ffidl（无 libffi 依赖），兼容 Windows XP。
- **CryptoVisionLib_xp.dll** — 静态链接的加密 DLL（ADVAPI32+KERNEL32+msvcrt），兼容 Windows XP。
- **third_party/** — 各库的源码与构建脚本（CryptoVisionLib、ffidl、patch_key、json_report、tag_reference）。
- **受保护资源。** 变体文件夹必须完整：exe + 各自的 `settings.cfg`、`.enc` 集与 DLL。不要重命名 exe，也不要混用不同变体的文件。
