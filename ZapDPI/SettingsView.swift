import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var configManager: ConfigManager
    @EnvironmentObject var vpnManager: VPNManager

    @State private var showLogLevelPicker = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Маршрутизация
                Section {
                    Toggle("Включить маршрутизацию", isOn: Binding(
                        get: { !configManager.currentConfig.routes.isEmpty },
                        set: { _ in }
                    ))
                    .tint(.blue)

                    Picker("Режим туннеля", selection: Binding(
                        get: { configManager.currentConfig.tunnelMode },
                        set: { configManager.currentConfig.tunnelMode = $0 }
                    )) {
                        ForEach(AppConfig.TunnelMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }

                    if !vpnManager.signingType.supportsSystemVPN && configManager.currentConfig.tunnelMode == .system {
                        Text("Системный VPN недоступен при бесплатной подписи. Используется внутрипроцессный режим.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Toggle("IPv6 трафик", isOn: $configManager.currentConfig.ipv6Enabled)
                        .tint(.green)

                    Text("Разрешить передачу трафика по протоколу IPv6")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Маршрутизация")
                }

                // MARK: - DNS
                Section {
                    Picker("DNS-сервер", selection: $configManager.currentConfig.dns) {
                        ForEach(DNSOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }

                    if configManager.currentConfig.dns == .custom {
                        TextField("Адреса DNS (через запятую)", text: Binding(
                            get: { configManager.currentConfig.customDNSServers.joined(separator: ", ") },
                            set: { configManager.currentConfig.customDNSServers = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                        ))
                    }
                } header: {
                    Text("DNS")
                } footer: {
                    Text("Выберите предпочтительный DNS-резолвер для обхода блокировок")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Расширенные настройки
                Section {
                    Picker("Уровень логов", selection: $configManager.currentConfig.logLevel) {
                        ForEach(AppConfig.LogLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                    NavigationLink("Диагностика приложения") {
                        DiagnosticsView()
                    }

                    NavigationLink("О приложении") {
                        AboutView()
                    }
                } header: {
                    Text("Расширенные настройки")
                }

                // MARK: - Управление конфигами
                Section {
                    ForEach(configManager.configs) { saved in
                        HStack {
                            Image(systemName: saved.isCurrent ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(saved.isCurrent ? .blue : .secondary)
                            Text(saved.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if saved.isCurrent {
                                Text("Текущий")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            try? configManager.loadConfig(saved)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            try? configManager.deleteConfig(configManager.configs[index])
                        }
                    }
                } header: {
                    Text("Сохранённые конфигурации")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Настройки")
        }
    }
}

/// Диагностика
struct DiagnosticsView: View {
    @EnvironmentObject var vpnManager: VPNManager

    var body: some View {
        List {
            Section("Статус VPN") {
                HStack {
                    Text("Статус")
                    Spacer()
                    Text(vpnManager.status.displayName)
                        .foregroundStyle(vpnManager.statusColor)
                }
                HStack {
                    Text("Режим подписи")
                    Spacer()
                    Text(vpnManager.signingType.rawValue.capitalized)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Системный VPN")
                    Spacer()
                    Text(vpnManager.isUsingSystemVPN ? "Да" : "Нет (In-App)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Локальный порт")
                    Spacer()
                    Text("\(vpnManager.localProxyPort)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Ограничения iOS") {
                Text("Бесплатная подпись: NetworkExtension недоступен")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Лимит памяти в фоне: 15–50 МБ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("JIT компиляция: требует активации в LiveContainer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Диагностика")
    }
}

/// О приложении
struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Версия")
                    Spacer()
                    Text("1.0.0 (каркас)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Ядро")
                    Spacer()
                    Text("sing-box / Xray-core")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Дизайн")
                    Spacer()
                    Text("Liquid Glass (iOS 18)")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Link("Политика конфиденциальности", destination: URL(string: "https://zapdpi.app/privacy")!)
                Link("Условия использования", destination: URL(string: "https://zapdpi.app/terms")!)
                Link("GitHub репозиторий", destination: URL(string: "https://github.com/zapdpi/zapdpi-ios")!)
            }

            Section {
                Text("Разработано для обхода цензуры и DPI-блокировок на iOS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("О приложении")
    }
}

#Preview {
    SettingsView()
        .environmentObject(ConfigManager())
        .environmentObject(VPNManager())
}
