import Combine
import Foundation

/// Управление конфигурациями: текущая, сохранённые, применение.
final class ConfigManager: ObservableObject {
    @Published var currentConfig = AppConfig()
    @Published var configs: [SavedConfig] = [
        SavedConfig(name: "Default", fileName: "default.json", isCurrent: true)
    ]

    private let logs = LogStore.shared

    /// Сохранение текущей конфигурации под новым именем.
    func saveCurrentConfig(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        configs = configs.map { saved in
            var copy = saved
            copy.isCurrent = false
            return copy
        }
        configs.append(
            SavedConfig(name: trimmed, fileName: "\(trimmed).json", isCurrent: true)
        )

        logs.log(.info, .config, "configuration saved: \"\(trimmed)\"")
    }

    /// Загрузка сохранённой конфигурации.
    func loadConfig(_ saved: SavedConfig) {
        configs = configs.map { item in
            var copy = item
            copy.isCurrent = (item.id == saved.id)
            return copy
        }

        logs.log(.info, .config, "configuration loaded: \"\(saved.name)\"")
    }

    /// Удаление конфигурации.
    func deleteConfig(_ saved: SavedConfig) {
        configs.removeAll { $0.id == saved.id }

        logs.log(.info, .config, "configuration deleted: \"\(saved.name)\"")
    }
}
