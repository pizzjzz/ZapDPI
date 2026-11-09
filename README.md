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

## 🏗️ Структура проекта

```
ZapDPI/
├── ZapDPI/
│   ├── ZapDPIApp.swift          # Точка входа (@main)
│   ├── ContentView.swift        # Корневой TabView + Liquid Glass таб-бар
│   ├── LiquidGlassTabBar.swift  # Плавающий стеклянный таб-бар (iOS 18)
│   ├── HomeView.swift           # Вкладка «Главная» (VPN + монитор трафика)
│   ├── ConfigView.swift         # Вкладка «Config» (JSON редактор + DPI настройки)
│   ├── SettingsView.swift       # Вкладка «Настройки» (Form + маршруты + DNS)
│   ├── Models.swift             # Модели данных (AppConfig, TunnelStatus, TrafficStats, и т.д.)
│   ├── VPNManager.swift         # Управление VPN (с fallback на In-App режим)
│   ├── TrafficMonitor.swift     # Мониторинг трафика в реальном времени
│   ├── ConfigManager.swift      # Сохранение/загрузка/импорт/экспорт конфигов
│   ├── Info.plist               # Конфигурация приложения
│   └── ZapDPI.entitlements      # Права доступа (entitlements)
├── .gitignore
└── README.md
```

## 🚀 Сборка .ipa

### macOS (нативный способ)

Требуется **Xcode** (скачать из Mac App Store).

1. Установите Xcode.
2. Откройте терминал и перейдите в папку проекта:
   ```bash
   cd /путь/к/ZapDPI
   ```
3. Создайте Xcode-проект (если ещё не создан):
   ```bash
   # В Xcode: File → New → Project → App → SwiftUI → Next
   # Скопируйте файлы из папки ZapDPI/ в проект
   ```
4. Откройте `ZapDPI.xcodeproj` в Xcode.
5. Выберите команду **Product → Archive** (или в терминале):
   ```bash
   xcodebuild -scheme ZapDPI -configuration Release -sdk iphoneos archive -archivePath ./build/ZapDPI.xcarchive
   ```
6. Экспортируйте `.ipa`:
   ```bash
   xcodebuild -exportArchive -archivePath ./build/ZapDPI.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath ./build/ipa
   ```
   Где `ExportOptions.plist` содержит метод экспорта (`ad-hoc`, `development` или `enterprise`).

7. Готовый `.ipa` будет в папке `./build/ipa/`.

### Windows (требуется macOS)

**Нельзя скомпилировать .ipa нативно в Windows**, так как Xcode доступен только на macOS. Варианты:

1. **Аренда Mac в облаке** (рекомендуется):
   - [MacStadium](https://macstadium.com/)
   - [MacInCloud](https://www.macincloud.com/)
   - [AWS EC2 Mac](https://aws.amazon.com/ec2/mac/)
   
   Подключитесь по RDP/VNC, установите Xcode и соберите проект по инструкции для macOS выше.

2. **GitHub Actions (macOS runner)** — автоматизация сборки:
   Создайте файл `.github/workflows/build.yml`:
   ```yaml
   name: Build ZapDPI iOS
   
   on:
     push:
       branches: [main]
   
   jobs:
     build:
       runs-on: macos-latest
       steps:
         - uses: actions/checkout@v4
         - name: Select Xcode version
           run: sudo xcode-select -switch /Applications/Xcode_15.app
         - name: Build archive
           run: xcodebuild -scheme ZapDPI -configuration Release -sdk iphoneos archive -archivePath ./build/ZapDPI.xcarchive
         - name: Export IPA
           run: xcodebuild -exportArchive -archivePath ./build/ZapDPI.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath ./build/ipa
         - name: Upload artifact
           uses: actions/upload-artifact@v4
           with:
             name: ZapDPI-ipa
             path: ./build/ipa/
   ```

3. **Виртуальная машина macOS на Windows** (VMware Workstation, VirtualBox):
   - Требуется образ macOS и соблюдение лицензионного соглашения Apple.
   - Установите Xcode внутри виртуальной машины и соберите проект стандартным способом.

### Linux (требуется macOS)

**Нельзя скомпилировать .ipa нативно в Linux**, так как Xcode и инструменты компиляции для iOS доступны только на macOS. Варианты те же, что и для Windows:

1. **Аренда Mac в облаке** (MacStadium, MacInCloud, AWS EC2 Mac).
2. **GitHub Actions с macOS-runner** (пример выше).
3. **Docker с macOS** — не официально поддерживается Apple, возможно нарушение лицензии, не рекомендуется для продакшена.

## 📦 Дистрибуция

Приложение можно установить следующими способами:

- **LiveContainer**
- **SideStore / AltStore / Sideloadly** (бесплатная подпись, 7 дней)
- **iLoader** (через ПК)
- **.ipa файл** — через указанные выше инструменты

## 🔐 Подпись и провижининг

- Для **бесплатной аккаунта Apple** (Apple ID) доступна только локальная подпись на 7 дней.
- Для полноценного `NetworkExtension` (системный VPN) требуется **Apple Developer Program** ($99/год) и соответствующий профиль провижининга.
- В файле `ZapDPI.entitlements` закомментированы ключи `com.apple.developer.networking.networkextension` — раскомментируйте их при наличии платной подписки.

## 🛠️ Стек технологий

- **SwiftUI** — пользовательский интерфейс
- **Combine** — реактивная обработка данных (трафик, статус VPN)
- **sing-box / Xray-core** — ядро обхода DPI (локально)
- **Liquid Glass** — стиль интерфейса (iOS 18)
- **JSON** — формат конфигурации ядра

## 📄 Лицензия

MIT License. См. файл `LICENSE` (при создании репозитория).

---

**Разработано для обхода цензуры и защиты приватности на iOS.**  
Если проект полезен — поставьте ⭐ на GitHub.