import Foundation
import UniformTypeIdentifiers

/// Управление конфигурациями: сохранение, загрузка, экспорт/импорт.
final class ConfigManager: ObservableObject {
    @Published var configs: [SavedConfig] = []
    @Published var currentConfig: AppConfig = AppConfig()

    private let documentsURL: URL
    private let configsDirectory: URL

    init() {
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        configsDirectory = documentsURL.appendingPathComponent("Configs", isDirectory: true)

        createConfigsDirectoryIfNeeded()
        loadConfigs()
    }

    private func createConfigsDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(
            at: configsDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    // MARK: - Сохранение / загрузка

    func saveCurrentConfig(name: String) throws {
        var config = currentConfig
        config.version = "1.0.0"

        let fileURL = configsDirectory.appendingPathComponent("\(name).json", isDirectory: false)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: fileURL, options: .atomic)

        let saved = SavedConfig(
            name: name,
            fileName: "\(name).json",
            createdAt: Date(),
            modifiedAt: Date(),
            isCurrent: true
        )

        // Помечаем остальные как неактуальные
        configs = configs.map { var c = $0; c.isCurrent = false; return c }
        configs.append(saved)

        try saveConfigsIndex()
    }

    func loadConfig(_ saved: SavedConfig) throws {
        let fileURL = configsDirectory.appendingPathComponent(saved.fileName, isDirectory: false)
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let config = try decoder.decode(AppConfig.self, from: data)

        currentConfig = config

        configs = configs.map { var c = $0; c.isCurrent = (c.id == saved.id); return c }
        try saveConfigsIndex()
    }

    func deleteConfig(_ saved: SavedConfig) throws {
        let fileURL = configsDirectory.appendingPathComponent(saved.fileName, isDirectory: false)
        try? FileManager.default.removeItem(at: fileURL)
        configs.removeAll { $0.id == saved.id }
        try saveConfigsIndex()
    }

    func exportConfig(_ saved: SavedConfig) -> URL? {
        let fileURL = configsDirectory.appendingPathComponent(saved.fileName, isDirectory: false)
        return fileURL
    }

    func importConfig(from url: URL, name: String) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        _ = try decoder.decode(AppConfig.self, from: data)

        let destURL = configsDirectory.appendingPathComponent("\(name).json", isDirectory: false)
        try FileManager.default.copyItem(at: url, to: destURL)

        let saved = SavedConfig(
            name: name,
            fileName: "\(name).json",
            createdAt: Date(),
            modifiedAt: Date(),
            isCurrent: false
        )
        configs.append(saved)
        try saveConfigsIndex()
    }

    // MARK: - Индекс конфигов

    private func saveConfigsIndex() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(configs)
        let indexURL = documentsURL.appendingPathComponent("configs_index.json", isDirectory: false)
        try data.write(to: indexURL, options: .atomic)
    }

    private func loadConfigs() {
        let indexURL = documentsURL.appendingPathComponent("configs_index.json", isDirectory: false)
        guard let data = try? Data(contentsOf: indexURL) else { return }
        configs = (try? JSONDecoder().decode([SavedConfig].self, from: data)) ?? []
    }

    // MARK: - Отправка конфига (заглушка)

    func shareConfig(_ saved: SavedConfig) -> URL? {
        return exportConfig(saved)
    }
}

/// Сохранённая конфигурация
struct SavedConfig: Codable, Identifiable {
    let id: UUID
    var name: String
    var fileName: String
    var createdAt: Date
    var modifiedAt: Date
    var isCurrent: Bool

    init(id: UUID = UUID(), name: String, fileName: String, createdAt: Date, modifiedAt: Date, isCurrent: Bool) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isCurrent = isCurrent
    }
}
