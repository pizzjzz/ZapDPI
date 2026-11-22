import Combine
import CryptoKit
import Foundation

// MARK: - Встроенная информация о ядре

enum CoreInfo {
    /// Версия sing-box, скомпилированная в приложение (меняется при сборке).
    static let bundledVersion = "1.12.0"
    static let coreRepository = "SagerNet/sing-box"
    static let geositeRepository = "SagerNet/sing-geosite"
    static let geoipRepository = "SagerNet/sing-geoip"

    static var geositeURL: URL {
        URL(string: "https://github.com/\(geositeRepository)/releases/latest/download/geosite.db")!
    }

    static var geoipURL: URL {
        URL(string: "https://github.com/\(geoipRepository)/releases/latest/download/geoip.db")!
    }
}

// MARK: - Версии

/// Простое сравнение версий вида `v1.12.0` / `1.12`.
struct SemanticVersion: Comparable, Equatable {
    let string: String
    private let components: [Int]

    init(_ string: String) {
        self.string = string

        var cleaned = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        while cleaned.hasPrefix("v") {
            cleaned.removeFirst()
        }

        components = cleaned.split(separator: ".").map { part in
            Int(part.prefix { $0.isNumber }) ?? 0
        }
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right {
                return left < right
            }
        }
        return false
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}

// MARK: - GitHub API

struct CoreRelease: Decodable, Equatable, Identifiable {
    let id: Int
    let tagName: String
    let name: String?
    let body: String?
    let htmlURL: URL
    let publishedAt: Date?
    let prerelease: Bool
    let assets: [CoreReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case id, name, body, prerelease, assets
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case publishedAt = "published_at"
    }
}

struct CoreReleaseAsset: Decodable, Equatable {
    let name: String
    let size: Int
    let downloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name, size
        case downloadURL = "browser_download_url"
    }
}

// MARK: - Хранилище

enum CoreStorage {
    static func rootDirectory() throws -> URL {
        let fileManager = FileManager.default
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = base.appendingPathComponent("ZapDPI", isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func geoDirectory() throws -> URL {
        let directory = try rootDirectory().appendingPathComponent("Geo", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func manifestURL() throws -> URL {
        try geoDirectory().appendingPathComponent("manifest.json")
    }

    static func geositePath() throws -> URL {
        try geoDirectory().appendingPathComponent("geosite.db")
    }

    static func geoipPath() throws -> URL {
        try geoDirectory().appendingPathComponent("geoip.db")
    }
}

/// Метаданные скачанных geo-баз. Обновляются независимо от релизов приложения.
struct GeoManifest: Codable, Equatable {
    var siteVersion: String
    var ipVersion: String
    var siteSHA256: String
    var ipSHA256: String
    var updatedAt: Date

    static func load() -> GeoManifest? {
        guard
            let url = try? CoreStorage.manifestURL(),
            let data = try? Data(contentsOf: url)
        else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(GeoManifest.self, from: data)
    }

    func save() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let url = try CoreStorage.manifestURL()
        try encoder.encode(self).write(to: url, options: .atomic)
    }
}

// MARK: - Состояния

enum CoreCheckState: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable
    case failed(String)

    var isChecking: Bool { self == .checking }
}

enum GeoUpdateState: Equatable {
    case idle
    case updating
    case updated
    case failed(String)

    var isUpdating: Bool { self == .updating }
}

enum CoreUpdateError: LocalizedError {
    case invalidURL
    case invalidResponse
    case http(Int)
    case emptyPayload
    case invalidPayload
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный адрес обновления"
        case .invalidResponse:
            return "Неожиданный ответ сервера"
        case .http(let code):
            return "GitHub вернул HTTP \(code)"
        case .emptyPayload:
            return "Сервер вернул пустой файл"
        case .invalidPayload:
            return "Файл не похож на данные правил sing-box"
        case .decoding:
            return "Не удалось разобрать ответ GitHub"
        }
    }
}

// MARK: - Менеджер обновлений

/// Обновление ядра и его данных.
///
/// - Версия самого sing-box проверяется по релизам `SagerNet/sing-box`.
///   На iOS исполняемый код нельзя подменить в рантайме, поэтому новая версия
///   ядра попадает в приложение только вместе со сборкой; менеджер сообщает,
///   что она доступна, и даёт ссылку на релиз.
/// - Geo-базы (`geosite.db`, `geoip.db`) скачиваются из репозиториев SagerNet
///   в `Application Support` и подхватываются ядром без обновления приложения.
@MainActor
final class CoreUpdater: ObservableObject {
    static let shared = CoreUpdater()

    @Published private(set) var coreState: CoreCheckState = .idle
    @Published private(set) var geoState: GeoUpdateState = .idle
    @Published private(set) var latestRelease: CoreRelease?
    @Published private(set) var geoManifest: GeoManifest? = GeoManifest.load()
    @Published private(set) var lastCheck: Date?

    @Published var autoCheckEnabled: Bool = UserDefaults.standard.object(forKey: Keys.autoCheck) as? Bool ?? true {
        didSet { UserDefaults.standard.set(autoCheckEnabled, forKey: Keys.autoCheck) }
    }

    @Published var autoUpdateGeoEnabled: Bool = UserDefaults.standard.object(forKey: Keys.autoUpdateGeo) as? Bool ?? true {
        didSet { UserDefaults.standard.set(autoUpdateGeoEnabled, forKey: Keys.autoUpdateGeo) }
    }

    private enum Keys {
        static let autoCheck = "core.autoCheck"
        static let autoUpdateGeo = "core.autoUpdateGeo"
        static let lastCheck = "core.lastCheck"
    }

    private let session: URLSession
    private let logs = LogStore.shared
    private let defaults = UserDefaults.standard

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 25
        configuration.timeoutIntervalForResource = 180
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration)

        lastCheck = defaults.object(forKey: Keys.lastCheck) as? Date
    }

    var installedVersion: SemanticVersion {
        SemanticVersion(CoreInfo.bundledVersion)
    }

    var isUpdateAvailable: Bool {
        coreState == .updateAvailable
    }

    // MARK: Автозапуск

    /// Вызывается при старте приложения: проверяет ядро (не чаще раза в 6 часов)
    /// и обновляет geo-базы (не чаще раза в неделю).
    func autoCheckIfNeeded() async {
        if autoCheckEnabled {
            let isStale = lastCheck.map { Date().timeIntervalSince($0) > 6 * 3600 } ?? true
            if isStale {
                await checkForUpdates()
            }
        }

        if autoUpdateGeoEnabled, needsGeoRefresh {
            await updateGeoAssets()
        }
    }

    private var needsGeoRefresh: Bool {
        guard let geoManifest else { return true }
        return Date().timeIntervalSince(geoManifest.updatedAt) > 7 * 24 * 3600
    }

    // MARK: Ядро

    func checkForUpdates() async {
        guard !coreState.isChecking else { return }

        coreState = .checking
        logs.log(.info, .core, "checking \(CoreInfo.coreRepository) for a new core")

        do {
            let release = try await fetchLatestRelease(repository: CoreInfo.coreRepository)
            latestRelease = release

            let latest = SemanticVersion(release.tagName)
            if latest > installedVersion {
                coreState = .updateAvailable
                logs.log(.warn, .core, "core update available: \(release.tagName) (bundled \(CoreInfo.bundledVersion))")
            } else {
                coreState = .upToDate
                logs.log(.info, .core, "core is up to date (\(CoreInfo.bundledVersion))")
            }

            lastCheck = Date()
            defaults.set(lastCheck, forKey: Keys.lastCheck)
        } catch {
            coreState = .failed(error.localizedDescription)
            logs.log(.error, .core, "core update check failed: \(error.localizedDescription)")
        }
    }

    // MARK: Geo-базы

    func updateGeoAssets() async {
        guard !geoState.isUpdating else { return }

        geoState = .updating
        logs.log(.info, .config, "geo assets: downloading latest rule-sets")

        do {
            let site = try await download(CoreInfo.geositeURL)
            let ip = try await download(CoreInfo.geoipURL)

            try site.data.write(to: try CoreStorage.geositePath(), options: .atomic)
            try ip.data.write(to: try CoreStorage.geoipPath(), options: .atomic)

            let manifest = GeoManifest(
                siteVersion: Self.dayString(),
                ipVersion: Self.dayString(),
                siteSHA256: site.sha256,
                ipSHA256: ip.sha256,
                updatedAt: Date()
            )
            try manifest.save()

            geoManifest = manifest
            geoState = .updated

            logs.log(
                .info,
                .core,
                "geo assets updated · geosite \(site.bytes) B · geoip \(ip.bytes) B · \(manifest.siteVersion)"
            )
        } catch {
            geoState = .failed(error.localizedDescription)
            logs.log(.error, .core, "geo assets update failed: \(error.localizedDescription)")
        }
    }

    // MARK: Сеть

    private func fetchLatestRelease(repository: String) async throws -> CoreRelease {
        guard let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest") else {
            throw CoreUpdateError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("ZapDPI/\(CoreInfo.bundledVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw CoreUpdateError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CoreUpdateError.http(http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(CoreRelease.self, from: data)
        } catch {
            throw CoreUpdateError.decoding
        }
    }

    private struct DownloadedAsset {
        let data: Data
        let sha256: String

        var bytes: Int { data.count }
    }

    private func download(_ url: URL) async throws -> DownloadedAsset {
        var request = URLRequest(url: url)
        request.setValue("ZapDPI/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw CoreUpdateError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CoreUpdateError.http(http.statusCode)
        }
        guard data.count > 1_024 else {
            throw CoreUpdateError.emptyPayload
        }

        // GitHub может вернуть HTML-страницу с кодом 200, если asset недоступен.
        if
            let head = String(data: data.prefix(16), encoding: .utf8),
            head.lowercased().contains("<!doctype")
        {
            throw CoreUpdateError.invalidPayload
        }

        return DownloadedAsset(data: data, sha256: Self.sha256(of: data))
    }

    // MARK: Утилиты

    private static func sha256(of data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func dayString() -> String {
        dayFormatter.string(from: Date())
    }
}
