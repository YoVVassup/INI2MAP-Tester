# INI2MAP Tester — сборка (RA2MT / RA2YRMT / MOMT)

**Документация:** [English](BUILD.md) · Русский · [中文](BUILD.zh.md)

## Варианты сборки

Все три варианта собираются из одного payload `INI2MAP-Tester.vfs`. Каждый вариант
самодостаточен в своей папке (`Build\<вариант>\`): exe + свой `settings.cfg`
+ свой набор `.enc` + DLL + помощники. Поведение задаёт имя exe: `main.tcl`
и `crypto.tcl` распознают starpack-варианты `MOMT.exe` / `RA2MT.exe` /
`RA2YRMT.exe` и ищут `settings.cfg`, `.enc` и DLL рядом с exe.

| Вариант | Аргумент build.bat | Результат | Конфигурация (gamemode) | Иконка | Version resource |
|---|---|---|---|---|---|
| **RA2MT** — Red Alert 2 | `build.bat ra2` | `Build\RA2MT\RA2MT.exe` | `settings-ra2.cfg` (`ra2`) | `RA2MT.ico` | `tools\version_ra2.res` |
| **RA2YRMT** — Yuri's Revenge | `build.bat yr` | `Build\RA2YRMT\RA2YRMT.exe` | `settings-yr.cfg` (`yr`) | `RA2YRMT.ico` | `tools\version_ra2yr.res` |
| **MOMT** — Mental Omega (по умолчанию) | `build.bat mo` | `Build\MOMT\MOMT.exe` | `settings.cfg` (`ares`) | `MOMT.ico` | `tools\version.res` |

`build.bat` без аргументов собирает все три варианта; неизвестный аргумент
останавливает сборку с `ERROR: unknown variant "<арг>"`.

### Зашифрованные ресурсы по вариантам

| Вариант | `.enc` файлы, копируемые в его папку |
|---|---|
| RA2MT | `rules.enc`, `ai.enc`, `art.enc`, `sound.enc`, `theme.enc`, `eva.enc`, `audio_ra2.enc` |
| RA2YRMT | `rulesmd.enc`, `aimd.enc`, `artmd.enc`, `soundmd.enc`, `thememd.enc`, `evamd.enc`, `audio_ra2.enc`, `audio_yr.enc` |
| MOMT | `rulesmo.enc`, `aimo.enc`, `artmo.enc`, `soundmo.enc`, `thememo.enc`, `evamo.enc`, `audio.enc`, `audio_ra2.enc`, `audio_yr.enc` |

Все `.enc` записываются в корень проекта командой
`crypto_utils.tcl --encrypt-originals` (см. README.ru.md, Перешифровка файлов).
`build.bat` не собирает вариант, пока хотя бы один файл его набора отсутствует.

## Необходимые инструменты

| Инструмент | Где взять | Назначение |
|---|---|---|
| **Tcl 8.6** | `C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe` | Интерпретатор Tcl — runtime для starpack и запуска sdx |
| **sdx.kit** | https://chiselapp.com/user/aspect/repository/sdx/uv/sdx-20110317.kit (119 KB) | Starkit Extension eXtensions — упаковка Tcl-приложения в starpack |
| **ResourceHacker** | Автоматически скачивается с https://www.angusj.com/resourcehacker/ при первой сборке (нужна версия **5.x+**, NuGet 4.7.34 НЕ работает со sdx starpack) | Встраивание иконки и version info в PE |

### Необходимые файлы

| Файл | Назначение |
|---|---|
| `tools/base.exe` | Копия `base-tcl8.6-thread-win32-ix86.exe` — runtime для starpack |
| `tools/version.res` | Скомпилированный version resource — MOMT |
| `tools/version_ra2.res` | Скомпилированный version resource — RA2MT (InternalName `RA2MT`) |
| `tools/version_ra2yr.res` | Скомпилированный version resource — RA2YRMT (InternalName `RA2YRMT`) |
| `MOMT.ico` | Иконка приложения — MOMT |
| `RA2MT.ico` | Иконка приложения — RA2MT |
| `RA2YRMT.ico` | Иконка приложения — RA2YRMT |

### Runtime файлы (в корне проекта, НЕ упаковываются в exe)

| Файл | Назначение |
|---|---|
| `CryptoVisionLib_xp.dll` | Криптографическая библиотека (NaCl/XSalsa20+Poly1305) |
| `settings.cfg` | Конфигурация MOMT (Tcl dict формат, gamemode `ares`) |
| `settings-ra2.cfg` | Конфигурация RA2MT (gamemode `ra2`) |
| `settings-yr.cfg` | Конфигурация RA2YRMT (gamemode `yr`) |
| `*.enc` | Зашифрованные ресурсы — наборы по вариантам, см. таблицу выше |
| `tags-*.cfg` | Конфигурации тегов для taglist (tags-ra2, tags-yr, tags-ares, tags-phobos, tags-ext). Генерируются из `third_party\tag_reference\tag_reference.xlsx`: `powershell -File third_party\tag_reference\generate_tags.ps1` |

## Порядок сборки

### Автоматическая сборка (build.bat)

```
build.bat          # все три варианта
build.bat ra2      # только RA2MT
build.bat yr       # только RA2YRMT
build.bat mo       # только MOMT
```

Скрипт выполняет следующие шаги:

0. **Синхронизация INI2MAP-Tester.vfs** — robocopy исходных директорий `.tcl` (`aicheck`, `checks`, `map_parser`, `rules_parser`, `validators`, `taglist`, `others`) и корневых модулей `.tcl` в `INI2MAP-Tester.vfs\lib\app-ini2map-tester\`, чтобы starpack соответствовал исходникам (шаг 0 в build.bat)
1. **Скачивание ResourceHacker** — если `tools\ResourceHacker.exe` отсутствует, автоматически скачивается с angusj.com
2. **Копирование base.exe** — создание копии Tcl runtime (нельзя оборачивать запущенный экземпляр)
3. **sdx wrap** — упаковка `INI2MAP-Tester.vfs/` в starpack (один раз, общий для всех вариантов):
   ```
   base-tcl8.6-thread-win32-ix86.exe sdx.kit wrap INI2MAP-Tester -runtime base.exe
   ```
   sdx создаёт файл без расширения (`INI2MAP-Tester`); он удаляется после сборки вариантов
4. **Для каждого варианта** (`:build_variant ra2|yr|mo`):
   - проверка, что все `.enc` набора варианта есть в корне проекта (иначе: `BUILD FAILED: missing <файл>`)
   - копирование обёрнутого kit в `Build\<вариант>\<вариант>.exe` (именно имя exe заставляет starpack резолвить свои runtime файлы)
   - удаление старых ресурсов и встраивание иконки + version info варианта через ResourceHacker:
     ```
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action delete -mask "ICONGROUP,," -log NUL
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action delete -mask "VERSION,," -log NUL
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action addoverwrite -resource "MOMT.ico" -mask "ICONGROUP,MAINICON," -log NUL
     tools\ResourceHacker.exe -open Build\MOMT\MOMT.exe -save Build\MOMT\MOMT.exe -action addoverwrite -resource "tools\version.res" -mask "VERSION,," -log NUL
     ```
     (RA2MT использует `RA2MT.ico` + `tools\version_ra2.res`, RA2YRMT — `RA2YRMT.ico` + `tools\version_ra2yr.res`)
   - копирование runtime файлов в `Build\<вариант>\`: `CryptoVisionLib_xp.dll`, собственный конфиг варианта как `settings.cfg`, его набор `.enc`, `tags-*.cfg`, `sha256.tcl`, `ffidl_xp.dll`, сгенерированный `pkgIndex.tcl`, `json_report.exe`
5. **Общее** — `json_report.exe` копируется в корень проекта (HTML-отчёт: `json_report mission.log`), туда же `ffidl_xp.dll` (для script mode)

### Ручная сборка (пошагово)

```bash
# 0. Синхронизировать INI2MAP-Tester.vfs с источниками (шаг 0 в build.bat: robocopy *.tcl в INI2MAP-Tester.vfs\lib\app-ini2map-tester\)

# 1. Копировать base.exe
copy "C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe" "tools\base.exe"

# 2. Обернуть в starpack
"C:\Tcl\bin\base-tcl8.6-thread-win32-ix86.exe" "tools\sdx.kit" wrap INI2MAP-Tester -runtime "tools\base.exe"

# 3. Для каждого варианта (пример: MOMT)
mkdir Build\MOMT
copy INI2MAP-Tester Build\MOMT\MOMT.exe
del INI2MAP-Tester
# ... команды ResourceHacker из build.bat (MOMT.ico + tools\version.res)

# 4. Скопировать runtime файлы
copy CryptoVisionLib_xp.dll Build\MOMT\
copy settings.cfg Build\MOMT\settings.cfg
copy rulesmo.enc aimo.enc artmo.enc soundmo.enc thememo.enc evamo.enc audio.enc audio_ra2.enc audio_yr.enc Build\MOMT\
copy tags-*.cfg Build\MOMT\
copy others\sha256\sha256.tcl Build\MOMT\
copy others\ffidl\ffidl_xp.dll Build\MOMT\
copy third_party\json_report\json_report.exe json_report.exe
```

Для RA2MT: `settings-ra2.cfg` -> `Build\RA2MT\settings.cfg` и набор RA2 `.enc`;
для RA2YRMT: `settings-yr.cfg` -> `Build\RA2YRMT\settings.cfg` и наборы YR `.enc`
(см. таблицы выше).

## Структура проекта

```
H:\MAP\
├── build.bat                    # Скрипт сборки (build.bat [ra2|yr|mo])
├── main.tcl                     # Точка входа (также в INI2MAP-Tester.vfs/main.tcl как bootstrap)
├── crypto.tcl                   # Модуль криптографии (ffidl)
├── cli.tcl                      # Парсер CLI аргументов
├── config.tcl                   # Загрузка конфигурации
├── constants.tcl                # Константы
├── data.tcl                     # Глобальные данные
├── logging.tcl                  # Логирование
├── orchestrator.tcl             # Оркестрация проверок
├── cache.tcl                    # Кэширование правил/аудио (пакетный режим)
├── utils.tcl                    # Общие утилиты
├── checks.tcl                   # Модуль проверок
├── validators.tcl               # Валидаторы триггеров/скриптов
├── rules_parser.tcl             # Парсер INI правил
├── map_parser.tcl               # Парсер .map файлов
├── audio_parser.tcl             # Парсер аудио ресурсов
├── crypto_utils.tcl             # Утилита шифрования/дешифровки
├── encrypt_v2.tcl               # V2 шифрование
├── check_key.tcl                # Проверка ключа
├── reencrypt_all.tcl            # Перешифровка всех файлов
├── taglist/taglist.tcl           # Валидация тегов
├── checks/*.tcl                 # 124+ модулей проверок
├── validators/*.tcl             # Модули валидации
├── rules_parser/*.tcl           # Подмодули парсера правил
├── map_parser/*.tcl             # Подмодули парсера карт
├── aicheck/*.tcl                # AI cross-checks
├── others/ffidl/                # Пакет ffidl (ffidl_xp.dll + pkgIndex.tcl)
├── others/sha256/               # Пакет SHA-256
├── third_party/                 # Исходники и скрипты сборки
│   ├── CryptoVisionLib/         # Исходник крипто-DLL + build_xp.bat
│   ├── ffidl/                   # Исходник ffidl + build_xp.bat
│   ├── patch_key/               # Исходник PatchDll + build_xp.bat
│   └── tag_reference/           # Tag Reference.xlsx, Regular_to_Excel.txt, generate_tags.ps1
├── CryptoVisionLib_xp.dll          # Криптографическая DLL
├── settings.cfg                 # Конфигурация MOMT (gamemode ares)
├── settings-ra2.cfg             # Конфигурация RA2MT (gamemode ra2)
├── settings-yr.cfg              # Конфигурация RA2YRMT (gamemode yr)
├── tags-*.cfg                   # Конфигурации тегов (генератор tags см. выше)
├── *.enc                        # Зашифрованные ресурсы (все три набора)
├── MOMT.ico                     # Иконка (MOMT)
├── RA2MT.ico                    # Иконка (RA2MT)
├── RA2YRMT.ico                  # Иконка (RA2YRMT)
├── INI2MAP-Tester.vfs/                    # Исходная VFS для sdx wrap
│   ├── main.tcl                 # Bootstrap (source → lib/app-ini2map-tester/main.tcl)
│   └── lib/app-ini2map-tester/            # Все .tcl файлы, others/, checks/, validators/...
├── tools/
│   ├── base.exe                 # Копия Tcl runtime
│   ├── sdx.kit                  # Starkit Extension eXtensions
│   ├── version.res              # Version resource (MOMT)
│   ├── version_ra2.res          # Version resource (RA2MT)
│   ├── version_ra2yr.res        # Version resource (RA2YRMT)
│   └── ResourceHacker.exe       # Скачивается с angusj.com при первой сборке
└── Build/
    ├── RA2MT/
    │   ├── RA2MT.exe            # Готовый starpack (Red Alert 2)
    │   ├── settings.cfg         # = settings-ra2.cfg
    │   └── *.enc + DLL, tags-*.cfg, sha256.tcl, ffidl_xp.dll, pkgIndex.tcl, json_report.exe
    ├── RA2YRMT/
    │   ├── RA2YRMT.exe          # Готовый starpack (Yuri's Revenge)
    │   ├── settings.cfg         # = settings-yr.cfg
    │   └── *.enc + DLL, tags-*.cfg, sha256.tcl, ffidl_xp.dll, pkgIndex.tcl, json_report.exe
    └── MOMT/
        ├── MOMT.exe             # Готовый starpack (Mental Omega)
        ├── settings.cfg         # = settings.cfg
        └── *.enc + DLL, tags-*.cfg, sha256.tcl, ffidl_xp.dll, pkgIndex.tcl, json_report.exe
```

## Запуск

### Через starpack (Build\<вариант>\)
```
H:\MAP\Build\MOMT\MOMT.exe <map_file>
H:\MAP\Build\RA2MT\RA2MT.exe <map_file>
H:\MAP\Build\RA2YRMT\RA2YRMT.exe <map_file>

H:\MAP\Build\MOMT\MOMT.exe --baseline
H:\MAP\Build\MOMT\MOMT.exe --baseline-filter baseline.log <map_file>
H:\MAP\Build\MOMT\MOMT.exe --batch <pattern|directory>
```

### Через скрипты (исходники)
```
C:\Tcl\bin\tclsh86.exe H:\MAP\main.tcl <map_file>
```

Интерактивный запуск: `__mission.bat`

## Примечания

- **Имя exe = вариант.** `main.tcl` и `crypto.tcl` сравнивают базовое имя exe со списком `momt|ra2mt|ra2yrmt`: только тогда `::app_dir` устанавливается в директорию exe (runtime файлы рядом с exe) и включается обнаружение starpack. Переименование exe ломает резолв runtime файлов.
- **sdx wrap** оборачивает файлы из `INI2MAP-Tester.vfs/` в starpack. Внутри exe VFS: `main.tcl` (bootstrap) и `lib/app-ini2map-tester/` (все модули, включая `cache.tcl`, `utils.tcl`). Один wrap обслуживает все три варианта.
- **CryptoVisionLib_xp.dll** не упаковывается в exe — ищется рядом с exe (starpack) или рядом со скриптами (script mode). Определяется через `::app_dir` в main.tcl.
- **Runtime файлы** (DLL, .enc, .cfg) копируются в `Build\<вариант>\` при сборке; каждый starpack получает файлы своего варианта.
- **Version info** и **иконка** встраиваются через ResourceHacker: `tools/version.res` (MOMT), `tools/version_ra2.res` (RA2MT), `tools/version_ra2yr.res` (RA2YRMT).
- **FileAlignment base kit** = 0x1000 (нестандартный). BeginUpdateResource не работает. Используйте только ResourceHacker.
- **ffidl_xp.dll** — статически слинкованная ffidl (без зависимостей libffi), совместимая с Windows XP.
- **CryptoVisionLib_xp.dll** — статически слинкованная крипто-DLL (ADVAPI32+KERNEL32+msvcrt), совместимая с Windows XP.
- **third_party/** — исходный код и скрипты сборки для библиотек (CryptoVisionLib, ffidl, patch_key, json_report, tag_reference).
