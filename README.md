# ZapDPI — iOS приложение для обхода DPI-блокировок

**ZapDPI** — приложение для iPhone, которое позволяет обходить цензуру и блокировки сайтов и приложений, установленные регуляторами по технологии DPI (Deep Packet Inspection). Приложение использует локальное ядро **sing-box** и не требует разворачивания собственного VPS.

## 🎨 Дизайн

Интерфейс построен на **SwiftUI** в стиле **Liquid Glass** — плавающий стеклянный таб-бар в стиле iOS 18, полупрозрачные карточки, градиентные кнопки и мягкие тени.

## 📱 Навигация (3 вкладки)

| Вкладка | Описание |
|---------|----------|
| **Главная** | Кнопка включения/выключения VPN, монитор входящего и исходящего трафика в реальном времени, информация о режиме работы (системный VPN / внутрипроцессный) |
| **Config** | Редактор JSON-конфигурации ядра sing-box/Xray-core с моноширинным шрифтом, настройки обхода DPI (фрагментация, TLS Client Hello, SNI, задержки пакетов), кнопка «Сохранить и применить» |
| **Настройки** | Маршрутизация (прямая / туннель), IPv6, выбор DNS (Cloudflare / Google / Quad9 / свой), уровень логов, диагностика, управление сохранёнными конфигурациями |

## ⚠️ Важные технические ограничения iOS

Из-за закрытости iOS и правил безопасности Apple:

1. **Бесплатная подпись (SideStore / AltStore / Sideloadly / 7 дней)** — системный фреймворк `NetworkExtension` (`NEPacketTunnelProvider`) **недоступен**. Приложение автоматически переходит в **внутрипроцессный режим (In-App Tun/Proxy)** без создания полноценного системного VPN-расширения.
2. **LiveContainer** — нет JIT-компиляции по умолчанию (может потребоваться активация через AltStore/SideStore). Жёсткие лимиты ОЗУ (обычно 15–50 МБ) — конфигурация не должна содержать миллионные списки заблокированных IP.
3. **Локальный обход DPI** работает только внутри TCP/UDP-сессий, которые приложение может перехватить на уровне локального туннеля (L3/L7). Не все сырые пакеты ядра iOS можно модифицировать.

## 📁 Структура репозитория

```
ZapDPI/
├── .github/
│   └── workflows/
│       └── build.yml          # GitHub Actions workflow для сборки .ipa
├── ExportOptions.plist        # Настройки экспорта .ipa (метод подписи)
├── .gitignore
├── README.md
└── ZapDPI/
    ├── ZapDPIApp.swift        # Точка входа (@main)
    ├── ContentView.swift      # Корневой TabView + Liquid Glass таб-бар
    ├── LiquidGlassTabBar.swift  # Плавающий стеклянный таб-бар (iOS 18)
    ├── HomeView.swift         # Вкладка «Главная» (VPN + монитор трафика)
    ├── ConfigView.swift       # Вкладка «Config» (JSON редактор + DPI настройки)
    ├── SettingsView.swift     # Вкладка «Настройки» (Form + маршруты + DNS)
    ├── Models.swift           # Модели данных
    ├── VPNManager.swift       # Управление VPN (с fallback на In-App режим)
    ├── TrafficMonitor.swift   # Мониторинг трафика в реальном времени
    ├── ConfigManager.swift    # Сохранение/загрузка/импорт/экспорт конфигов
    ├── Info.plist             # Конфигурация приложения
    └── ZapDPI.entitlements    # Права доступа (entitlements)
```

> ⚠️ **Важно:** Для компиляции `.ipa` необходим полноценный Xcode-проект (`.xcodeproj`). Репозиторий содержит исходные `.swift` файлы — `.xcodeproj` создаётся в Xcode вручную (см. инструкцию ниже).

---

## 🚀 Сборка .ipa (обязательно на macOS)

### Шаг 1: Создайте Xcode-проект

Требуется **macOS** с установленным **Xcode** (Mac App Store).

1. Откройте Xcode
2. `File → New → Project`
3. Выберите **App** → `Next`
4. Заполните:
   - **Product Name:** ZapDPI
   - **Team:** ваша Apple ID / Team (или добавьте позже)
   - **Bundle Identifier:** `com.zapdpi.ios`
   - **Interface:** SwiftUI
   - **Language:** Swift
5. Сохраните проект в папку `ZapDPI/` (рядом с этим README)

### Шаг 2: Добавьте исходные файлы в проект

Перетащите в Xcode все файлы из папки `ZapDPI/`:
- `ZapDPIApp.swift`
- `ContentView.swift`
- `LiquidGlassTabBar.swift`
- `HomeView.swift`
- `ConfigView.swift`
- `SettingsView.swift`
- `Models.swift`
- `VPNManager.swift`
- `TrafficMonitor.swift`
- `ConfigManager.swift`
- `Info.plist`
- `ZapDPI.entitlements`

### Шаг 3: Настройте подпись (Signing & Capabilities)

1. Выберите проект в навигаторе Xcode → цель **ZapDPI**
2. Вкладка **Signing & Capabilities**
3. Поставьте галочку **Automatically manage signing**
4. Выберите ваш Apple ID / Team
5. Bundle Identifier: `com.zapdpi.ios`

### Шаг 4: Закоммитьте .xcodeproj

```bash
git add ZapDPI.xcodeproj/
git commit -m "Add Xcode project"
git push origin main
```

### Шаг 5: Соберите .ipa

**В Xcode:**
1. `Product → Archive`
2. В окне Organizer нажмите **Distribute App**
3. Выберите метод: `Ad Hoc` / `Development` / `App Store`
4. Экспортируйте `.ipa`

**Или через терминал (macOS):**
```bash
cd /путь/к/ZapDPI

xcodebuild -scheme ZapDPI \
  -configuration Release \
  -sdk iphoneos \
  -archivePath ./build/ZapDPI.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath ./build/ZapDPI.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build/ipa
```

Готовый `.ipa` будет в папке `./build/ipa/`.

---

## 🔄 GitHub Actions (macOS runner)

Сборка через GitHub Actions возможна только на **macOS-раннере** (`macos-latest`). Xcode не работает на Windows и Linux нативно.

Файл `.github/workflows/build.yml` уже настроен:
- Автоматически выбирает установленную версию Xcode
- Собирает архив через `xcodebuild archive`
- Экспортирует `.ipa`
- Загружает артефакт в GitHub Actions

### Требования для работы Actions:
1. В репозитории должен быть `.xcodeproj` (создан в Xcode, см. выше)
2. Файл `ExportOptions.plist` с настройками подписи
3. Секреты GitHub (если нужна автоматическая подпись):
   - `APPLE_ID` — ваш Apple ID
   - `APPLE_ID_PASSWORD` — пароль от Apple ID (или App-Specific Password)

---

## 📦 Дистрибуция

Приложение можно установить следующими способами:

- **LiveContainer**
- **SideStore / AltStore / Sideloadly** (бесплатная подпись, 7 дней)
- **iLoader** (через ПК)
- **.ipa файл** — через указанные выше инструменты

## 🔐 Подпись и провижининг

- Для **бесплатной аккаунта Apple** (Apple ID) доступна только локальная подпись на 7 дней.
- Для полноценного `NetworkExtension` (системный VPN) требуется **Apple Developer Program** ($99/год) и соответствующий профиль провижининга.
- В файле `ZapDPI.entitlements` ключи `com.apple.developer.networking.networkextension` закомментированы — раскомментируйте их при наличии платной подписки.

## 🛠️ Стек технологий

- **SwiftUI** — пользовательский интерфейс
- **Combine** — реактивная обработка данных (трафик, статус VPN)
- **sing-box / Xray-core** — ядро обхода DPI (локально)
- **Liquid Glass** — стиль интерфейса (iOS 18)
- **JSON** — формат конфигурации ядра

## 📄 Лицензия

MIT License.

---

**Разработано для обхода цензуры и защиты приватности на iOS.**  
Если проект полезен — поставьте ⭐ на GitHub.