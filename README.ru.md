<p align="center">
  <h1 align="center">INI2MAP Tester</h1>
  <p align="center">Инструмент валидации карт для моддинга Command & Conquer Red Alert 2 / Yuri's Revenge</p>
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
  <b>Дешифровка • Парсинг • Валидация • Отчёт</b>
</p>

---

## Возможности

```
┌─────────────────────────────────────────────────────────────────┐
│  🔐 ШИФРОВАНИЕ                                                  │
│  ├── V2 Мультифакторное: hash DLL + salt + HKDF-SHA256          │
│  ├── V1 Legacy: DEFAULT_KEY (XSalsa20 + Poly1305)               │
│  └── Автоопределение по magic bytes "CV02"                      │
├─────────────────────────────────────────────────────────────────┤
│  📁 ПОДДЕРЖКА ФАЙЛОВ                                            │
│  ├── Карты: .map, .yrm, .mpr                                    │
│  ├── Правила: .enc (зашифрованные INI)                          │
│  └── Аудио: .enc (зашифрованные .idx)                           │
├─────────────────────────────────────────────────────────────────┤
│  ✅ ВАЛИДАЦИЯ                                                   │
│  ├── 124 структурных проверки (оружие, боеголовки, анимации)    │
│  ├── AI кросс-проверки (предпосылки, ссылки, цвета)             │
│  ├── 26 WAE-проверки карты + целостность триггеров              │
│  ├── Валидация звуковых ресурсов                                │
│  └── Пакетный режим с JSON-отчётом                              │
├─────────────────────────────────────────────────────────────────┤
│  🎮 ИГРОВЫЕ РЕЖИМЫ                                              │
│  ├── RA2 (Red Alert 2)                                          │
│  ├── YR (Yuri's Revenge)                                        │
│  ├── Ares (расширение модов)                                    │
│  └── Phobos (расширение модов)                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Требования

```
┌─────────────────────────────────────────────────────────────────┐
│  ПРЕДВАРИТЕЛЬНЫЕ ТРЕБОВАНИЯ                                     │
│                                                                 │
│  ✓ ActiveTcl 8.6 (32-bit)                                       │
│    └── tclsh86.exe должен быть в PATH или запускаться напрямую  │
│                                                                 │
│  ✓ ffidl_xp.dll (совместимый с XP, самодостаточный)             │
│    └── Поставляется в others/ffidl/                             │
│                                                                 │
│  ✓ CryptoVisionLib_xp.dll (совместимая с XP, статическая)       │
│    └── Поставляется в third_party/CryptoVisionLib/              │
│                                                                 │
│  ○ PatchDll.exe (опциональная)                                  │
│    └── Нужна только для переключения ключа шифрования           │
└─────────────────────────────────────────────────────────────────┘
```

## Структура файлов

```
<папка проекта>\
│
├── 📄 main.tcl                  Точка входа
├── 📄 __mission.bat             Интерактивный лаунчер
├── 📄 settings.cfg              Конфигурация MOMT (хеш, соль, режим игры)
├── 📄 settings-ra2.cfg          Конфигурация RA2MT (тот же хеш/соль, файлы RA2)
├── 📄 settings-yr.cfg           Конфигурация RA2YRMT (тот же хеш/соль, файлы YR)
├── 🎨 MOMT.ico                  Иконка приложения (сборка MOMT)
├── 🎨 RA2MT.ico                 Иконка приложения (сборка RA2MT)
├── 🎨 RA2YRMT.ico               Иконка приложения (сборка RA2YRMT)
│
├── 📁 original_files/           Оригинальные файлы для перешифровки
│   ├── Mental Omega/            9 файлов: rulesmo, aimo, artmo, soundmo, thememo, evamo, audio*
│   ├── Red Alert 2/             7 файлов: rules, ai, art, sound, theme, eva, audio_ra2
│   └── Red Alert 2 Yuris Revenge/  8 файлов: rulesmd, aimd, artmd, soundmd, thememd, evamd, audio*
│
├── 🔒 rulesmo.enc               Набор правил MOMT (rulesmo, aimo, artmo, soundmo, thememo, evamo)
├── 🔒 rules.enc                 Набор правил RA2MT (rules, ai, art, sound, theme, eva)
├── 🔒 rulesmd.enc               Набор правил RA2YRMT (rulesmd, aimd, artmd, soundmd, thememd, evamd)
├── 🔒 audio_ra2.enc             Аудио-индексы (audio_ra2, audio_yr, audio - общие для всех вариантов)
│
├── 📄 crypto.tcl                Модуль криптографии (ffidl + DLL)
├── 📄 crypto_utils.tcl          Утилита шифрования/дешифровки
├── 📄 cli.tcl                   Парсер аргументов командной строки
├── 📄 config.tcl                Загрузчик настроек
├── 📄 constants.tcl             Игровые константы
├── 📄 data.tcl                  Глобальные массивы данных
├── 📄 logging.tcl               Запись логов
├── 📄 orchestrator.tcl          Главный оркестратор валидации
├── 📄 cache.tcl                 Кэширование правил/аудио для пакетного режима
├── 📄 utils.tcl                 Общие утилиты
├── 📄 audio_parser.tcl          Парсер аудио-индексов (дешифрует .enc в памяти)
├── 📄 rules_parser.tcl          Парсер INI правил
├── 📁 rules_parser/             Подмодули парсера правил (8 файлов)
├── 📄 map_parser.tcl            Парсер файлов карт
├── 📁 map_parser/               Подмодули парсера карт (10 файлов)
├── 📄 validators.tcl            Диспетчер валидаторов
├── 📁 validators/               Модули валидаторов (9 файлов)
├── 📄 checks.tcl                Диспетчер проверок + построение индекса
├── 📁 checks/                   Модули проверок (125 файлов: 124 модуля + загрузчик)
├── 📁 aicheck/                  Модули AI кросс-проверок (7 файлов: 5 модулей + aicheck.tcl + core.tcl)
├── 📁 taglist/                  Конфигурации валидации тегов
├── 📁 others/                   Внешние зависимости
│   ├── ffidl/                   Пакет ffidl (ffidl_xp.dll + pkgIndex.tcl)
│   └── sha256/                  Пакет SHA-256 для Tcl
├── 📁 third_party/              Исходный код и скрипты сборки
│   ├── CryptoVisionLib/         Исходник крипто-DLL + build_xp.bat
│   ├── ffidl/                   Исходник ffidl + build_xp.bat
│   ├── json_report/             Исходник JSON -> HTML отчёта + build_xp.bat
│   ├── patch_key/               Исходник PatchDll + build_xp.bat
│   └── tag_reference/           Tag Reference + генератор tags-*.cfg
├── 📁 tools/                    Бинарии сборки + скрипты проверок (sync/verify/check/run_one)
├── 📁 tests/                    Тестовые файлы (131 файлов, 1124 тестов)
└── 📁 Build/                    Собранные самодостаточные исполняемые файлы (build.bat)
    ├── RA2MT/                   RA2MT.exe + settings.cfg + свой набор .enc + DLL и помощники
    ├── RA2YRMT/                 RA2YRMT.exe + settings.cfg + свой набор .enc + DLL и помощники
    └── MOMT/                    MOMT.exe + settings.cfg + свой набор .enc + DLL и помощники
```

## Быстрый старт

### Запуск валидации одной карты

```bash
cd /d <папка проекта>
tclsh86.exe main.tcl all01.map
```

Если `tclsh86` не в PATH — укажите интерпретатор явно (остальные пути относительные):

```bash
"path\to\tclsh86.exe" main.tcl all01.map
```

**Пример вывода:**

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

Запуск с `--format json` пишет `mission.log` в формате JSON, после чего
`json_report.exe mission.log` собирает из него автономный HTML-отчёт
(карточки сводки, чипы фильтра severity, живой поиск; `-o out.html` — путь
вывода, `-open` — открыть в браузере). Утилита 32-битная и работает на
Windows XP (PE32, подсистема 5.1, без ucrt).

### Запуск с опциями

```bash
tclsh86.exe main.tcl --batch "*.map"
```

### Интерактивный лаунчер

Дважды кликните на `__mission.bat` для интерактивного меню:

```
  [1] Validate map
  [2] Generate baseline (INI checks only)
  [3] Validate map with baseline filter
  [4] Validate + HTML report (mission.html)
  [5] Batch validate all maps + HTML per map
  [0] Cancel
```

Лаунчер также принимает аргументы напрямую (без меню):

```bash
__mission.bat --batch-html Build           # директория
__mission.bat --batch-html "Build\*.map"   # шаблон wildcard
```

Оба варианта валидируют все подходящие карты с `--format json` (без
автооткрытия лога), а затем запускают `json_report.exe` для каждого
`<mapfile>.log`, записывая `<mapfile>.html` рядом с картой.

В каждой вариации сборки есть `Build\<variant>\__batch.bat`: перетащите на
него любое количество файлов карт, папок или wildcard-шаблонов — он валидирует
их и создаст HTML-отчёт для каждой карты (браузер не открывается автоматически).

### Собранные исполняемые файлы (build.bat)

`build.bat` собирает три варианта; каждый исполняемый файл самодостаточен в
своей папке (exe + свой `settings.cfg` + свой набор `.enc` + DLL + помощники):

| Вариант | Исполняемый файл | Конфигурация | gamemode | Игра / мод |
|---|---|---|---|---|
| **RA2MT** | `Build\RA2MT\RA2MT.exe` | `settings-ra2.cfg` | `ra2` | Red Alert 2 |
| **RA2YRMT** | `Build\RA2YRMT\RA2YRMT.exe` | `settings-yr.cfg` | `yr` | Red Alert 2: Yuri's Revenge |
| **MOMT** | `Build\MOMT\MOMT.exe` | `settings.cfg` | `ares` | Mental Omega (по умолчанию) |

```bash
build.bat          # все три варианта
build.bat ra2      # только RA2MT
build.bat yr       # только RA2YRMT
build.bat mo       # только MOMT
```

Полную процедуру сборки (иконки, version-ресурсы, runtime файлы) см. в
[BUILD.ru.md](BUILD.ru.md).

## Опции командной строки

```
┌────────────────────┬─────────────────────────────────────────────┐
│  ОПЦИЯ             │  ОПИСАНИЕ                                   │
├────────────────────┼─────────────────────────────────────────────┤
│  <map_file>        │  Путь к файлу .map/.yrm/.mpr для валидации  │
│  --batch           │  Пакетный режим — валидация нескольких карт │
│  --mode <name>     │  Переключение режима: ra2/yr/ares/phobos    │
│  --salt <hex>      │  Соль для V2 дешифровки (64 hex символа)    │
│  --cfg <path>      │  Пользовательский путь к settings.cfg       │
│  --no-log-open     │  Не открывать лог автоматически             │
│  --timing          │  Показать время обработки по фазам          │
│  --quiet           │  Подавить вывод в консоль (ошибки видны)    │
│  --format <fmt>    │  Формат отчёта: text (по умолчанию), json   │
│  --baseline        │  Сгенерировать baseline.log из INI          │
│  --baseline-filter │  Подавить известные предупреждения          │
│  --help            │  Показать справку                           │
└────────────────────┴─────────────────────────────────────────────┘
```

## Конфигурация (settings.cfg)

В проекте три конфигурации. Они одинаковы по `crypto_dll_expected_hash` и
`v2_salt` и отличаются только файлами правил и режимом игры; при сборке каждый
вариант получает свою копию как `settings.cfg` рядом со своим exe:

| Файл | Вариант | Файлы правил | gamemode |
|---|---|---|---|
| `settings.cfg` | MOMT (по умолчанию) | `rulesmo`, `aimo`, `artmo`, `soundmo`, `thememo`, `evamo` | `ares` |
| `settings-ra2.cfg` | RA2MT | `rules`, `ai`, `art`, `sound`, `theme`, `eva` | `ra2` |
| `settings-yr.cfg` | RA2YRMT | `rulesmd`, `aimd`, `artmd`, `soundmd`, `thememd`, `evamd` | `yr` |

Примеры ниже показывают `settings.cfg` (MOMT).

### V2 конфигурация (по умолчанию)

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

### V1 конфигурация (legacy)

Для V1 шифрования оставьте `v2_salt` пустым и используйте незашифрованные `.enc` файлы:

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

### Справочник ключевых настроек

```
┌────────────────────────────────┬─────────────────────────────────────┐
│  НАСТРОЙКА                     │  ОПИСАНИЕ                           │
├────────────────────────────────┼─────────────────────────────────────┤
│  crypto_dll_expected_hash      │  SHA-256 хеш CryptoVisionLib_xp.dll │
│  v2_salt                       │  Соль для V2 дешифровки (64 hex)    │
│  gamemode                      │  ra2 / yr / ares / phobos           │
│  sound_validation              │  Включить валидацию звуковых        │
│                                │  ресурсов                           │
│  ini_encoding                  │  Переопределить кодировку INI       │
│                                │  (или авто)                         │
│  savelog                       │  Дописывать в существующий лог      │
│  writeanims                    │  Записывать лог анимаций            │
│  showunused                    │  Показывать отчёт об                │
│                                │  неиспользуемых элементах           │
│  paranoid                      │  Строгая валидация                  │
│  auto_open_log                 │  Автооткрытие лога в редакторе      │
│  sound_check_audio             │  Проверять ресурсы audio.idx        │
│  sound_warn_unused             │  Предупреждать о неиспользуемых     │
│                                │  звуках                             │
│  sound_warn_duplicate_resources│  Предупреждать о дублирующихся      │
│                                │  ресурсах                           │
│  sound_warn_orphan_resources   │  Предупреждать об осиротевших       │
│                                │  ресурсах                           │
└────────────────────────────────┴─────────────────────────────────────┘
```

## Шифрование

INI2MAP Tester использует **V2 мультифакторное шифрование** (по умолчанию) или **V1 legacy шифрование**.

### V2 Мультифакторное (текущее)

```
┌─────────────────────────────────────────────────────────────────┐
│  V2 ВЫВОД КЛЮЧА                                                 │
│                                                                 │
│  ┌──────────────┐                                               │
│  │  Файл DLL    │──SHA-256──▶ [32B dll_hash]                    │
│  └──────────────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │  Соль        │──(32B случайная)──▶ [32B salt]                │
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
│  │  Упаковка случайного файла-ключа         │                   │
│  │  random_key → XSalsa20+Poly1305 → wrapped│                   │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  Формат зашифрованного файла:            │                   │
│  │  [CV02 magic 4B]                         │                   │
│  │  [wrapped_key 72B] (nonce24 + enc_key48) │                   │
│  │  [nonce 24B]                             │                   │
│  │  [ciphertext + MAC 16B]                  │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

Три.required factorа:
1. **Хеш DLL** — SHA-256 CryptoVisionLib_xp.dll
2. **Соль** — случайное 32-байтное значение, передаётся отдельно
3. **Зашифрованный файл** — содержит упакованный случайный файл-ключ

### V1 Legacy

```
┌─────────────────────────────────────────────────────────────────┐
│  V1 ВЫВОД КЛЮЧА                                                 │
│                                                                 │
│  ┌──────────────────────────────────────────┐                   │
│  │  DEFAULT_KEY[32] (вшит в DLL)            │                   │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  XSalsa20 + Poly1305 (NaCl secretbox)   │                    │
│  └──────────────────────────────────────────┘                   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────────┐                   │
│  │  Формат зашифрованного файла:            │                   │
│  │  [nonce 24B]                             │                   │
│  │  [ciphertext + MAC 16B]                  │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

Один factor: DEFAULT_KEY, вшитый в DLL.

Автоопределение по наличию magic bytes "CV02".

## Перешифровка файлов

Если вам нужно изменить ключ шифрования или перешифровать файлы, используйте `PatchDll.exe` и `crypto_utils.tcl`.

### Шаг 1: Генерация нового ключа (опционально)

PatchDll генерирует новый случайный DEFAULT_KEY в DLL:

```bash
PatchDll.exe CryptoVisionLib_xp.dll
```

**Вывод:**

```
Generated new random key: ec3fa41ed8762c7733845e2a957a6b2dd995a0d6f23751dafc947755db09e557
Successfully patched DEFAULT_KEY in CryptoVisionLib_xp.dll
New SHA-256 hash: e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f
Updated settings.cfg with the new hash.
```

### Шаг 2: Генерация V2 соли (опционально)

```bash
PatchDll.exe --v2 CryptoVisionLib_xp.dll
```

**Вывод:**

```
DLL SHA-256: e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f
Generated salt: <64-hex salt>

To encrypt files with this salt:
  tclsh crypto_utils.tcl --salt <64-hex salt> <files...>

To use in INI2MAP Tester:
  tclsh main.tcl --salt <64-hex salt> <map_file>

IMPORTANT: Keep this salt secret! Share it only with trusted users.
```

### Шаг 3: Обновление settings.cfg

Обновите `crypto_dll_expected_hash` и `v2_salt` в settings.cfg значениями из шагов 1-2.

### Шаг 4: Шифрование .ini файлов

**Пакетный режим (рекомендуется)** — шифрует всё содержимое `original_files/`
и его подпапок (18 `.ini` + 6 `.idx`, 24 файла) и записывает `.enc` в корневую директорию проекта:

```bash
tclsh86.exe crypto_utils.tcl --encrypt-originals --dry-run   # предпросмотр: что будет записано
tclsh86.exe crypto_utils.tcl --encrypt-originals             # записать .enc в корень проекта
tclsh86.exe crypto_utils.tcl --encrypt-originals --out temp\enc   # записать в относительный подкаталог
```

Соль берётся из `settings.cfg` (`v2_salt`); переопределяется флагом `--salt <hex>`.
Сначала проверяется хеш `CryptoVisionLib_xp.dll` (`crypto_dll_expected_hash`),
`--force` отключает эту проверку. Код выхода `0` — только если все файлы
зашифрованы успешно.

**Ручной режим** — по одному файлу:

```bash
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/rulesmo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/aimo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/artmo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/soundmo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/thememo.ini"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/evamo.ini"
```

Каждая команда записывает `<base>_enc<ext>` рядом с входным файлом (`original_files/Mental Omega/rulesmo.ini` -> `original_files/Mental Omega/rulesmo_enc.ini`); `<base>.enc` в корень проекта записывает только `--encrypt-originals`.

### Шаг 5: Шифрование .idx файлов

Аудио-индексы также необходимо зашифровать:

```bash
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/audio_ra2.idx"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/audio_yr.idx"
tclsh86.exe crypto_utils.tcl --salt <salt_hex> "original_files/Mental Omega/audio.idx"
```

### Шаг 6: Копирование DLL

Скопируйте пропатченную `CryptoVisionLib_xp.dll` в корень проекта (команду выполняйте оттуда):

```bash
copy /Y CryptoVisionLib_xp.dll .
```

## Дешифровка файлов

Для дешифровки V2 .enc файла обратно в открытый текст:

```bash
tclsh86.exe crypto_utils.tcl --salt <salt_hex> rulesmo.enc
```

**Вывод:**

```
CryptoVisionLib version: 2.0.0
Key is valid
DLL SHA-256: e70ba6e736d5a40e6be26ab88b58eeac010d445ad09082aa930c60635773487f
Encrypting (v2): rulesmo.enc -> rulesmo_dec.ini
  OK
```

Создаёт `rulesmo_dec.ini` в текущей директории.

Для дешифровки V1 .enc файла:

```bash
tclsh86.exe crypto_utils.tcl rulesmo.enc
```

## Добавление новых карт

1. Разместите файлы `.map`, `.yrm` или `.mpr` в директории MAP
2. Запустите валидацию:
   ```bash
   tclsh86.exe main.tcl your_map.map
   ```
3. Проверьте `mission.log` на наличие ошибок и предупреждений

## Пакетный режим

Валидация нескольких карт одновременно:

```bash
tclsh86.exe main.tcl --batch "*.map" --format json
```

Пакетный режим всегда записывает отдельный лог рядом с каждой картой
(`<mapfile>.log`, например `all01.map.log`) вместо единого `mission.log`.
При `--format json` это JSON-логи, которые `json_report.exe` превращает в
автономный HTML-отчёт (карточки сводки, фильтры по серьёзности, живой поиск);
в текстовом формате по умолчанию записывается обычный текстовый отчёт.

```bash
json_report.exe all01.map.log    # -> all01.map.html
```

`__mission.bat --batch-html <pattern|dir>` и помощник
`Build\<variant>\__batch.bat` объединяют оба шага — см.
[Интерактивный лаунчер](#интерактивный-лаунчер).

**Пример JSON-вывода:**

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

## Устранение неполадок

```
┌─────────────────────────────────────────────────────────────────┐
│  ФАТАЛЬНАЯ ОШИБКА: CryptoVisionLib_xp.dll hash mismatch!        │
├─────────────────────────────────────────────────────────────────┤
│  DLL была изменена или заменена.                                │
│  Исправление: Обновите crypto_dll_expected_hash в settings.cfg  │
│                                                                 │
│  $ PatchDll.exe CryptoVisionLib_xp.dll                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  ФАТАЛЬНАЯ ОШИБКА: V2 encrypted file detected but no salt       │
│  provided (pass --salt or provide settings.cfg): <file>         │
├─────────────────────────────────────────────────────────────────┤
│  Исправление: Установите v2_salt в settings.cfg или передайте   │
│  --salt <hex> в командной строке                                │
│                                                                 │
│  $ tclsh86.exe main.tcl --salt <64-hex salt> your_map.map       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  ФАТАЛЬНАЯ ОШИБКА: Cannot load Ffidl from ffidl_xp.dll: <error> │
├─────────────────────────────────────────────────────────────────┤
│  Исправление: Убедитесь что ffidl_xp.dll находится в корне      │
│  проекта или в директории others/ffidl/                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  ФАТАЛЬНАЯ ОШИБКА: sha256 package not available.                │
├─────────────────────────────────────────────────────────────────┤
│  Исправление: Убедитесь что директория others/sha256/ существует│
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  ФАТАЛЬНАЯ ОШИБКА: Crypto key validation failed!                │
├─────────────────────────────────────────────────────────────────┤
│  DEFAULT_KEY в DLL повреждена или неверна.                      │
│  Исправление: Перепатчите DLL                                   │
│                                                                 │
│  $ PatchDll.exe CryptoVisionLib_xp.dll                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  ПРЕДУПРЕЖДЕНИЕ: No audio index files could be loaded.          │
│  Sound resource validation will be skipped.                     │
├─────────────────────────────────────────────────────────────────┤
│  Проверьте что audio_ra2.enc, audio_yr.enc, audio.enc           │
│  существуют и зашифрованы с правильной солью.                   │
└─────────────────────────────────────────────────────────────────┘
```

## Архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                        INI2MAP Tester                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  main.tcl ──────────────────────────────────────────────────┐   │
│      │                                                      │   │
│      ├── cli.tcl ──────────── Парсер аргументов            │    │
│      │                                                      │   │
│      ├── config.tcl ───────── Загрузка settings.cfg         │   │
│      │                                                      │   │
│      ├── crypto.tcl ───────── Инициализация ffidl, загрузка │   │
│      │                       DLL, проверка хеша             │   │
│      │                                                      │   │
│      ├── cache.tcl ────────── Кэширование (пакетный режим) │    │
│      │                                                      │   │
│      ├── utils.tcl ────────── Общие утилиты                 │   │
│      │                                                      │   │
│      └── orchestrator.tcl ─── Главный пайплайн валидации   │    │
│              │                                              │   │
│              ├── rules_parser.tcl + rules_parser/           │   │
│              │   └── Дешифровка + парсинг .enc файлов       │   │
│              │                                              │   │
│              ├── taglist/                                   │   │
│              │   └── Валидация имён тегов                   │   │
│              │                                              │   │
│              ├── audio_parser.tcl                           │   │
│              │   └── Дешифровка + парсинг аудио .enc файлов │   │
│              │                                              │   │
│              ├── map_parser.tcl + map_parser/               │   │
│              │   └── Парсинг файлов .map/.yrm/.mpr          │   │
│              │                                              │   │
│              ├── validators.tcl + validators/               │   │
│              │   └── Валидация триггеров/событий/действий   │   │
│              │                                              │   │
│              ├── checks.tcl + checks/                       │   │
│              │   └── 124 структурных проверок               │   │
│              │                                              │   │
│              └── aicheck/                                   │   │
│                  └── AI кросс-проверки                       │  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Каталог проверок

Каждая находка выводится на одном из трёх уровней серьёзности. Код завершения
процесса отражает наихудший найденный уровень:

| Уровень | Значение | Код выхода |
|---|---|---|
| `ERROR` | Карта упадёт, испортит данные или не загрузится в игре | **2** |
| `WARNING` | Известный игровой баг или неподдерживаемая конфигурация | **1** |
| `NOTICE` | Подозрительный паттерн, стоит проверить (может быть намеренным) | не влияет на код выхода |

`0` = нет ошибок/предупреждений, `1` = есть только предупреждения, `2` = есть
ошибки, `3` = фатальная ошибка (необработанное исключение или сбой инициализации крипто-модуля). Ошибки CLI и конфигурации также завершаются с кодом `1`.

### Где выполняются проверки

| Этап | Модули | Что проверяется |
|---|---|---|
| INI правил | `rules_parser.tcl` + `rules_parser/` (8 файлов) | Расшифровка и структура `.enc` INI-файлов |
| Аудио | `audio_parser.tcl` | Расшифровка аудио-индекса и кросс-ссылки |
| Файл карты | `map_parser.tcl` + `map_parser/` (10 файлов) | Каждая секция карты: синтаксис, число полей, размещение, дома, вейпоинты, теги, туннели, триггеры |
| Целостность | `validators.tcl` + `validators/` (9 файлов) | Граф включения/выключения триггеров, события/действия/скрипты, связи TaskForce/TeamType, отчёт об неиспользуемых объектах |
| Кросс-проверки правил | `checks.tcl` + `checks/` (124 модуля) | Валидация правил RA2/YR, сгруппирована ниже |
| AI кросс-проверки | `aicheck/` (5 модулей) | AI-предпосылки, ссылки, ART, цвета, воксели |
| Теги | `taglist/` | Форматы имён и секций тегов |

### Проверки целостности карты (реализованы заново по WAE)

26 проверок реализовано заново по эталонной реализации [WAE](https://github.com/CnCNet/WorldAlteringEditor) (World Altering Editor) (*MapLoader* /
*MapIssueChecker*):

| Что ловит | Уровень | Модуль |
|---|---|---|
| Триггер без событий (никогда не сработает) или без действий (ничего не делает) | notice | `validators/trigger_integrity.tcl` |
| Триггер стартует выключенным и никогда не включается другим триггером | notice | `validators/trigger_integrity.tcl` |
| Триггер включается другим триггером, но никогда не выключается | notice | `validators/trigger_integrity.tcl` |
| Триггер включает сам себя | notice | `validators/trigger_integrity.tcl` |
| Цепочка LinkedTrigger замыкается на самом себе (краш игры) | notice | `validators/trigger_integrity.tcl` |
| Дом из `[Basic] Player=` отсутствует или не PlayerControlled | notice | `map_parser/basic_map.tcl` |
| Владелец триггера ссылается на несуществующий HouseType | warning | `map_parser/team_script_taskforce_triggers.tcl` |
| Объявление триггера менее чем из 8 полей | warning | `map_parser/team_script_taskforce_triggers.tcl` |
| Триггер с более чем 18 действиями (буфер парсинга игры) | notice | `map_parser/team_script_taskforce_triggers.tcl` |
| Скрипт с более чем 50 действиями | notice | `validators/scripts.tcl` |
| Пара включение/выключение с несовпадающими уровнями сложности | notice | `validators/trigger_integrity.tcl` |
| Два дома с одинаковым ININame (испорченный список домов) | notice | `map_parser/houses_countries.tcl` |
| `Allies=` дома указывает на несуществующий дом | warning | `map_parser/houses_countries.tcl` |
| Дом карты без `Country=` | warning | `map_parser/houses_countries.tcl` |
| Запись `[AITriggerTypes]` с числом полей не равным 18 | warning | `map_parser/aitriggers.tcl` |
| `FOLLOWS_INDEX` юнита: само-следование, невалидный ведомый, дубли ведущих | notice | `map_parser/structures_units_infantry.tcl` |
| Два пехотных юнита на одной суб-ячейке | warning | `map_parser/structures_units_infantry.tcl` |
| Апгрейды зданий, применённые на карте, конфликты `PowersUpBuilding`, лишние апгрейды | warning | `map_parser/structures_units_infantry.tcl` |
| `[VariableNames]`: невалидный или дублирующийся индекс локальной переменной | warning | `map_parser/houses_countries.tcl` |
| Искажённая запись `[Tubes]` (поля, координаты, ориентация) | warning | `checks/tubes_limit.tcl` |
| Ландшафт размещён вне используемой области карты | warning | `map_parser/celltags_house_data.tcl` |
| Индекс вейпоинта, не являющийся неотрицательным целым | warning | `map_parser/houses_countries.tcl` |
| Действие с фиксированным P1, отличающимся от документированного значения (WAE TriggerFix, таблица modenc) | notice | `validators/actions.tcl` |
| Событие Building Exists (32), которое дом триггера никогда не сможет выполнить: нет ни предустановленной постройки, ни базового узла, ни юнита/TeamType с деплоем в неё (WAE MapIssueChecker, только ИИ-дома одиночной игры) | notice | `validators/events.tcl` |
| Запись `[Aircraft]`: мало полей, неопределённый тип, неверный дом или тег | error | `map_parser/structures_units_infantry.tcl` |
| Событие, которое должно быть прикреплено («Вошёл…», «Мост уничтожен», локальные ячейные события), осталось без вложений | notice | `validators/trigger_integrity.tcl` |

Числовые диапазоны вейпоинтов проверяются как ошибки времени разбора
функцией `num2wp` (`map_parser/core.tcl`; лимиты 25/702 захардкожены там
же, значения `MAX_WAYPOINTS_*` из `constants.tcl` использует только
`report_unused.tcl`).

Не реализованы заново по WAE клеточно-тайловые проверки `ImpassableTile` и
`TiberiumUnsupportedRamp` (*MapIssueChecker*) и валидация ландшафта
`PostCheckMap` (*MapLoader*): им нужен расшифрованный рельеф
`IsoMapPack5` и данные оверлея, а загрузчик намеренно пропускает
бинарные секции (`binary_sections` в `map_parser/load_map.tcl`:
`IsoMapPack5`, `OverlayDataPack`, `OverlayPack`, `Preview`, `PreviewPack`,
`SpecialFlags`), чтобы многомегабайтные блоки не доходили до парсера.

### Проверки правил (`checks/`, 124 модуля)

Каждый модуль валидирует расшифрованные INI правил против известных игровых
багов и документирует правило и ссылки в шапке файла. Теги уровней:
**E** = ошибка, **W** = предупреждение, **N** = уведомление.

**Структура и размещение карты (3)** — размеры карты, лимиты туннелей и ландшафта:
`map` (E/W/N) · `terrain_foundation` (E) · `tubes_limit` (E/W)

**Триггеры, TeamTypes и TaskForces (5)** — дубликаты и сломанные конфигурации команд:
`aggressive_transport_teams` (W) · `suicide_aircraft` (W) · `taskforce_duplicates` (E) · `transports_return_bug` (W) · `veteran_level_reinforcement` (N)

**Здания и база (25)** — конфликты флагов зданий, предпосылки, доки, апгрейды:
`armory` (E/W/N) · `bunker` (W/N) · `cloning` (E) · `cloning_facility` (W) · `construction_yard` (E) · `distributed_fire` (W/N) · `free_unit` (W) · `gap_radius_in_cells` (W) · `hospital` (W) · `laser_fence` (W) · `laser_fence_post` (W/N) · `number_of_docks` (W) · `pad_aircraft` (W) · `powers_unit` (W) · `prerequisite_override` (W) · `repairable` (W) · `requires_stolen_tech` (W/N) · `secret_lab_bonus_count` (W) · `secret_lab_techlevel_m1` (W) · `super_gap_radius` (W) · `turret_occupy` (W) · `turret_voxel_newtheater` (W) · `unit_absorb_dock_unload` (W) · `unit_repair_building` (W/N) · `weapons_factory_building` (W)

**Авиация (6)** — стыковка, стрельба и краши авиации:
`airport_bound` (W) · `balloon_hover` (W/N) · `carryall` (W/N) · `fire_once_aircraft` (E) · `rot_aircraft` (W) · `strafing_burst` (N)

**Юниты, пехота и техника (40)** — флаги TechnoType, лимиты и здравый смысл опций Ares/Phobos:
`airstrike` (E/W) · `attach_effects` (W) · `crashable` (W/N) · `crew_flags` (E/W) · `damage_particle_systems_infantry` (W) · `deployed_crushable` (W) · `dont_score` (W) · `fraidycat` (W) · `guard_range` (W) · `gunner` (W) · `ifv_weapon_system` (E/W/N) · `infantry_flags` (E/W) · `insignificant` (W/N) · `invisible_in_game` (W) · `is_gattling` (W) · `is_simple_deployer` (W/N) · `land_targeting` (W) · `locomotor_bugs` (E/W) · `missile_spawn` (W) · `no_spawn_alt` (E/W) · `omni_crusher` (W) · `open_topped` (W) · `powered_unit` (W) · `primary_none_secondary` (W) · `sensors_sight` (W) · `sight_limit` (W/N) · `size_limit` (W/N) · `slowdown_distance` (W) · `speed_limit` (W/N) · `spray_attack` (W) · `strength_zero` (W) · `thief_guard_mode` (W) · `trainable_agent` (W/N) · `turret_count_weapon_count` (E/W) · `undeploys_into` (W/N) · `unit_crate_type_base_unit` (W) · `vehicle_unloading_water` (N) · `walk_rate_zero` (E) · `warpable_temporal` (W) · `weaponx_ifv` (W)

**Оружие и боеголовки (21)** — флаги и параметры, ломающие урон или роняющие игру:
`affects_allies` (W) · `animlist_negative_damage` (W) · `areafire` (W) · `cell_spread` (E) · `cloak_stop` (W) · `culling` (W) · `direct_rocker` (W) · `infinite_mind_control` (W) · `is_laser` (W) · `is_locomotor` (W/N) · `is_sonic` (W) · `laser_parameters` (N) · `laser_thickness` (W) · `limbo_launch` (W) · `mind_control` (W) · `minimum_range` (W) · `nuke_maker` (W) · `range_weapon` (W/N) · `sonic_mindcontrol` (W) · `spawner_spawns` (E) · `temporal_particle` (W/N)

**Снаряды (6)** — флаги снарядов с лимитами движка или известными багами:
`ag_projectile` (W) · `airburst_split` (E/W) · `cluster` (W) · `inviso` (W) · `splits_limit` (N) · `vertical_projectile` (E/W)

**Анимации, частицы и ландшафт (7)** — ссылки и значения анимаций/частиц:
`dig` (E/W) · `is_animated` (W) · `light_size` (E) · `next_particle` (W) · `share_source` (W) · `state_ai_advance` (W/N) · `wind_effect_particles` (E)

**Глобальные правила и секции (7)** — `[General]`, `[AudioVisual]`, `[Countries]` и секционные переопределения:
`armor_types` (E/W/N) · `attacking_aircraft_sight_range` (E/W) · `curley_shuffle` (W) · `selfheal_frames` (E/W) · `shake_screen` (E/W) · `speed_aircraft_mult` (W) · `verses_map_override` (N)

**Супероружия (4)** — ссылки на типы SW и их использование:
`auxbuilding_superweapons` (W) · `spysat_bugs` (W/N) · `use_charge_drain_superweapon` (W) · `weapontype_superweapon` (W)

### AI кросс-проверки (`aicheck/`, 5 модулей)

`ref_check` (E/W/N) кросс-проверяет оружие, боеголовки, снаряды и анимации;
`prereq_check` (W) валидирует предпосылки зданий и TechLevels; `art_check` (W)
валидирует ART-данные; `color_check` (W/N) валидирует секцию `[Colors]`;
`voxel_check` (W/N) валидирует свойства VoxelAnim.

## Покрытие тестами

```
┌─────────────────────────────────────────────────────────────────┐
│  ТЕСТОВЫЙ НАБОР: 1124 тестов в 131 тестовых файлах              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ████████████████████████████████████████████████████ 100%      │
│  Все тесты проходят                                             │
│                                                                 │
│  Основные модули:                                               │
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
│  Плюс 108 отдельных файлов тестов проверок (395 доп. тестов)    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

Запуск всего набора тестов встроенным раннером:

```console
tclsh86 tests/run_all.tcl             # все тестовые файлы
tclsh86 tests/run_all.tcl -v          # вывод каждого тестового файла
tclsh86 tests/run_all.tcl -k crypto   # только файлы с "crypto" в имени
```

Код возврата `0` — только если прошли все тестовые файлы.

Медленные гейты намеренно отделены от `run_all.tcl` (минуты, а не секунды):

```console
tclsh86 tests/run_e2e.tcl             # E2E: 3 контрольные карты против числовых базлайнов
tclsh86 tests/run_e2e.tcl -exe        # смоук собранного Build\MOMT\MOMT.exe после сборки
tclsh86 tests/fuzz_maps.tcl           # мутанты TEST.map через полный CLI
```

`run_e2e.tcl` сравнивает счётчики Errors/Warnings/Notices и код выхода
`sov01.map`, `TEST.map` и `all01.map` с числовыми базлайнами — числа
намеренные: они ловят и проверки, которые молча исчезли; обновляйте таблицу в
`tests/run_e2e.tcl` осознанно при изменении находок. `fuzz_maps.tcl` детерминированно
мутирует `TEST.map` (фиксированный LCG-сид, `-s` для воспроизведения, `-n` — количество)
и проверяет только процессный инвариант: код выхода в диапазоне `0..2` без
необработанного исключения; провалившиеся мутанты вместе с их `mission.log`
сохраняются в `tests/_fuzz_maps/` (вне `tests/_tmp`, который `run_all` стирает
после зелёного прогона). Быстрый `tests/test_fuzz_parser.tcl` (внутри `run_all`)
фаззит парсер и валидаторы событий/действий детерминированным мусором.

Весь стек проверок (боксы README, синк INI2MAP-Tester.vfs + MD5, юнит-тесты; `-E2E`
добавляет оба медленных гейта, `-Fuzz` — карт-фаззинг) собран в один скрипт:

```console
powershell -File tools\verify_all.ps1          # быстро: боксы + синк + run_all
powershell -File tools\verify_all.ps1 -E2E     # + run_e2e + смоук MOMT.exe
powershell -File tools\verify_all.ps1 -Fuzz    # + медленный fuzz карт
```

Отдельные шаги: `tools\check_boxes.py`, `tools\sync_vfs.ps1` (whitelist шага 0
парсится из `build.bat`, поэтому расхождение невозможно), `tools\run_one.ps1`
(замер времени одного запуска карты).

## Лицензия

```
┌─────────────────────────────────────────────────────────────────┐
│  ЛИЦЕНЗИЯ: CC BY-NC-SA 4.0                                      │
│  АВТОР: YoWassup                                                │
│                                                                 │
│  https://creativecommons.org/licenses/by-nc-sa/4.0/             │
│                                                                 │
│  ✓ Attribution — Вы должны дать соответствующую кредиту         │
│  ✓ NonCommercial — Вы не можете использовать материал в         │
│    коммерческих целях                                           │
│  ✓ ShareAlike — Если вы изменяете, трансформируете или          │
│    создаёте производный материал, вы должны распространять      │
│    свои вклады под той же лицензией, что и оригинал.            │
└─────────────────────────────────────────────────────────────────┘
```

## Благодарности

### Начальные проекты

На основе анализа и адаптации этих инструментов для моддинга RA2/YR:

| Проект | Автор | Описание | Ссылка |
|--------|-------|----------|--------|
| **AICheck** | G-E | Комплексный анализ rules/art/ai ini | [PPM Forums](https://ppmforums.com/topic-68095/aicheck-a-script-for-extensively-analyzing-rulesartaiini/?highlight=AICHECK) |
| **SoundCheck** | G-E | Проверка ошибок в звуках | [PPM Forums](https://ppmforums.com/topic-68094/soundcheck-a-script-to-check-for-mistakes-related-to-sounds-in-rulesartsoundini/?highlight=SOUNDCHECK) |
| **MisTest** | G-E | Тестирование кода миссий | [PPM Forums](https://ppmforums.com/topic-68090/mistest-a-script-to-test-mission-map-code-and-check-map-objects-for-errors/?highlight=MISTEST) |
| **TagList** | G-E | Проверка валидности тегов в rules.ini | [PPM Forums](https://ppmforums.com/topic-68088/taglist-a-script-to-check-validity-of-tags-within-rulesini/?highlight=TAGLIST) |
| **WAE** | CnCNet | World Altering Editor — обработчики ошибок MapLoader/MapIssueChecker + 26 проверок целостности карты (реализованы заново) | [GitHub](https://github.com/CnCNet/WorldAlteringEditor) |

### Ресурсы

Документация, использованная как справочник по игровой механике:

| Ресурс | Описание | Ссылка |
|--------|----------|--------|
| **Ares Docs** | Документация расширения Ares | [ares-developers.github.io](https://ares-developers.github.io/Ares-docs/index.html#) |
| **Phobos Docs** | Документация расширения Phobos | [phobos.readthedocs.io](https://phobos.readthedocs.io/en/latest/) |
| **MODENC** | Справочник тегов INI для RA2/YR | [modenc.renegadeprojects.com](https://modenc.renegadeprojects.com/Main_Page) |

### Технологии

| Технология | Назначение | Лицензия |
|------------|-----------|----------|
| **Tcl 8.6** | Язык скриптов | Tcl License |
| **ffidl 0.9** | Tcl FFI к нативным библиотекам | BSD |
| **libsodium** | Криптография (NaCl) | ISC License |
| **CryptoVisionLib** | Кастомная крипто-DLL | CC BY-NC-SA 4.0 |
