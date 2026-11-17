import Combine
import Foundation

/// Управление конфигурациями: текущая, сохранённые, применение.
final class ConfigManager: ObservableObject {
    @Published var currentConfig = AppConfig()
    @Published var configs: [SavedConfig] = [
        SavedConfig(name: "Default", fileName: "default.json", isCurrent: true)
    ]

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
    }

    /// Загрузка сохранённой конфигурации.
    func loadConfig(_ saved: SavedConfig) {
        configs = configs.map { item in
            var copy = item
            copy.isCurrent = (item.id == saved.id)
            return copy
        }
    }

    /// Удаление конфигурации.
    func deleteConfig(_ saved: SavedConfig) {
        configs.removeAll { $0.id == saved.id }
    }
}
