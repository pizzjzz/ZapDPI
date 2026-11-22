# ZapDPI — iOS приложение для обхода DPI-блокировок

**ZapDPI** — приложение для iPhone, которое обходит цензуру и блокировки сайтов, реализованные через DPI (Deep Packet Inspection). Приложение использует локальное ядро **sing-box** и не требует собственного VPS.

Проект собирается **без Mac** — через [xtool](https://github.com/xtool-org/xtool), кроссплатформенную замену Xcode (Linux / WSL / macOS).

## 🎨 Дизайн

Интерфейс на **SwiftUI** в стиле **Liquid Glass**: плавающий стеклянный таб-бар, полупрозрачные карточки, градиентные кнопки и мягкие тени.

## 📱 Навигация (4 вкладки)

| Вкладка | Описание |
|---------|----------|
| **Главная** | Кнопка включения/выключения VPN, монитор входящего и исходящего трафика в реальном времени |
| **Config** | Редактор JSON-конфигурации ядра sing-box/Xray-core, настройки обхода DPI (фрагментация, TLS Client Hello, SNI, задержки пакетов), кнопка «Сохранить и применить» |
| **Логи** | Поток логов ядра sing-box: уровни (trace…fatal), подсистемы (`[core]`, `[tun]`, `[dns]`, `[route]`…), поиск, фильтр по уровню, пауза, автопрокрутка, экспорт и копирование |
| **Настройки** | Маршрутизация, IPv6, выбор DNS (Cloudflare / Google / Quad9 / свой), уровень логов, диагностика, сохранённые конфигурации |

## 🌊 Liquid Glass

Таб-бар использует **настоящий Liquid Glass** из iOS 26 (`glassEffect`,
`GlassEffectContainer`, `glassEffectID`): капсулы вкладок сливаются в единую
стеклянную полосу, выбранная вкладка тонируется, подсветка морфится при
переключении, а `.interactive()` даёт отклик на касания. На iOS 17–25
автоматически включается матовый фолбэк (`.ultraThinMaterial`).


## ⚠️ Ограничения iOS

1. **Бесплатная подпись** (SideStore / AltStore / Sideloadly / xtool с обычным Apple ID) — фреймворк `NetworkExtension` (`NEPacketTunnelProvider`) **недоступен**. Приложение работает в **внутрипроцессном режиме (In-App Tun/Proxy)** без системного VPN-расширения.
2. **LiveContainer** — нет JIT по умолчанию (включается через AltStore/SideStore). Жёсткие лимиты ОЗУ (обычно 15–50 МБ).
3. **Локальный обход DPI** работает только внутри TCP/UDP-сессий, которые приложение может перехватить (L3/L7), не все сырые пакеты iOS можно модифицировать.

## 🏗️ Структура проекта

Проект — обычный **SwiftPM-пакет** (такой же, как создаёт `xtool new`):

```
ZapDPI/
├── Package.swift                # SwiftPM-манифест (library-таргет ZapDPI)
├── xtool.yml                    # Конфигурация xtool (схема version 1)
├── Sources/ZapDPI/
│   ├── ZapDPIApp.swift          # Точка входа (@main)
│   ├── ContentView.swift        # Корневой экран + Liquid Glass таб-бар
│   ├── LiquidGlassTabBar.swift  # Плавающий стеклянный таб-бар
│   ├── HomeView.swift           # Вкладка «Главная» (VPN + монитор трафика)
│   ├── ConfigView.swift         # Вкладка «Config» (JSON-редактор + DPI)
│   ├── LogsView.swift           # Вкладка «Логи» (поток логов ядра)
│   ├── SettingsView.swift       # Вкладка «Настройки» (Form, маршруты, DNS)
│   ├── Models.swift             # Модели данных
│   ├── CoreLog.swift            # Логи ядра: уровни, источники, LogStore
│   ├── VPNManager.swift         # Управление VPN (fallback на In-App режим)
│   ├── TrafficMonitor.swift     # Мониторинг трафика
│   └── ConfigManager.swift      # Сохранение/загрузка конфигов
└── Support/
    ├── Info.plist               # Только добавляемые/переопределяемые ключи
    └── ZapDPI.entitlements      # Права доступа (пустые по умолчанию)
```

`xtool.yml`:

```yaml
version: 1
bundleID: com.zapdpi.ios
product: ZapDPI
infoPath: Support/Info.plist
entitlementsPath: Support/ZapDPI.entitlements
```

- `version` — версия схемы `xtool.yml`, всегда `1`.
- `bundleID` — идентификатор приложения (xtool добавит префикс `XTL-…` при установке на устройство).
- `product` — имя product из `Package.swift`, который превращается в `.app`.
- `infoPath` — plist, который **дополняет** автоматически сгенерированный `Info.plist`.
- `entitlementsPath` — entitlements, которые добавляются к подписи.

## 🚀 Сборка через xtool

### Предварительные требования

| Что | Зачем |
|-----|-------|
| **WSL2** (Windows) | xtool работает в Linux (в Windows — только через WSL) |
| **Swift 6.4** | `swift --version` должен показывать `Swift version 6.4` |
| **usbmuxd + libimobiledevice-utils** | Связь с iPhone из Linux |
| **Xcode 27.1 (`Xcode.xip`)** | Из него xtool собирает Darwin Swift SDK |
| **Apple ID** | Бесплатного достаточно (подпись на 7 дней) |

#### 1. Проброс USB в WSL

Установите [USBIPD](https://learn.microsoft.com/en-us/windows/wsl/connect-usb) и подключите iPhone к WSL:

```powershell
usbipd list
usbipd bind --busid <busid>
usbipd attach --wsl --busid <busid>
```

Если появляется `Error: AFCClient.Error.muxError`, используйте обходной путь через iTunes (см. [issue #19](https://github.com/xtool-org/xtool/issues/19#issuecomment-2898986718)).

#### 2. Swift и usbmuxd (в WSL)

```bash
# Swift 6.4: https://swift.org/install/linux
swift --version

sudo apt-get install usbmuxd libimobiledevice-utils
ideviceinfo   # проверка, что iPhone виден
```

#### 3. Установка xtool

```bash
curl -fL \
  "https://github.com/xtool-org/xtool/releases/latest/download/xtool-$(uname -m).AppImage" \
  -o xtool
chmod +x xtool
sudo mv xtool /usr/local/bin/

xtool --help
```

#### 4. Первичная настройка

Скачайте **Xcode 27.1** с <https://developer.apple.com/download/all/?q=Xcode> (нужен вход в Apple ID) и выполните:

```bash
xtool setup
```

Мастер попросит:
- режим логина: `API Key` (платный аккаунт) или `Password` (любой Apple ID);
- путь к `Xcode.xip`.

Проверка SDK:

```bash
swift sdk list
# darwin
```

### Сборка и установка на iPhone

```bash
cd ZapDPI
xtool dev
```

`xtool dev` собирает пакет, подписывает приложение, устанавливает и запускает его на подключённом iPhone. Готовый бандл можно посмотреть в `./xtool/ZapDPI.app`.

Только собрать, без установки:

```bash
xtool dev build
```

> Отдельных команд `xtool generate` / `xtool export` **не существует**. xtool собирает `.app` напрямую из SwiftPM-пакета; `.ipa` при необходимости упаковывается из `./xtool/ZapDPI.app` вручную (`Payload/ZapDPI.app` → zip → `.ipa`).

### Другие команды

```bash
xtool devices      # список подключённых устройств
xtool install      # установить собранное приложение
xtool launch       # запустить приложение на устройстве
xtool uninstall    # удалить приложение
```

## 🔐 Подпись

- **Бесплатный Apple ID**: подпись на 7 дней, `NetworkExtension` недоступен → приложение автоматически использует In-App режим.
- **Apple Developer Program ($99/год)**: можно включить системный VPN. Для этого раскомментируйте `com.apple.developer.networking.networkextension` в `Support/ZapDPI.entitlements`.

## 📦 Дистрибуция

- **LiveContainer**
- **SideStore / AltStore / Sideloadly** (бесплатная подпись, 7 дней)
- **iLoader** (через ПК)

## 🛠️ Стек

- **SwiftUI** — интерфейс
- **Combine** — реактивные менеджеры состояния
- **SwiftPM + xtool** — сборка без Mac
- **sing-box / Xray-core** — ядро обхода DPI (локально)
- **JSON** — формат конфигурации ядра

## 📄 Лицензия

MIT License.
