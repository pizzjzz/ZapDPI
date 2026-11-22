import Combine
import Foundation

/// Уровни логов ядра (соответствуют уровням logrus в sing-box).
enum CoreLogLevel: String, CaseIterable, Identifiable, Comparable {
    case trace
    case debug
    case info
    case warn
    case error
    case fatal

    var id: String { rawValue }

    var label: String { rawValue.uppercased() }

    var priority: Int {
        switch self {
        case .trace: return 0
        case .debug: return 1
        case .info: return 2
        case .warn: return 3
        case .error: return 4
        case .fatal: return 5
        }
    }

    static func < (lhs: CoreLogLevel, rhs: CoreLogLevel) -> Bool {
        lhs.priority < rhs.priority
    }
}

/// Подсистема sing-box, из которой пришла запись.
enum CoreLogSource: String, CaseIterable, Identifiable {
    case core
    case app
    case config
    case dns
    case route
    case tun
    case outbound

    var id: String { rawValue }

    var tag: String { "[\(rawValue)]" }
}

/// Одна запись лога ядра.
struct CoreLogEntry: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let level: CoreLogLevel
    let source: CoreLogSource
    let message: String

    var timeString: String {
        CoreLogEntry.timeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

/// Хранилище логов ядра.
///
/// Сюда пишет сам sing-box (через log-коллбэк), а также менеджеры приложения.
/// Пока ядро не встроено в бинарник, записи формирует `VPNManager` —
/// это те же строки, которые печатает sing-box при старте туннеля.
final class LogStore: ObservableObject {
    static let shared = LogStore()

    /// Сколько записей держим в памяти (старые вытесняются).
    let capacity = 2_000

    @Published private(set) var entries: [CoreLogEntry] = []
    @Published private(set) var isPaused = false
    @Published var selectedLevel: CoreLogLevel?
    @Published var searchText = ""
    @Published var isAutoScrollEnabled = true

    /// Снимок списка на момент паузы — новые записи продолжают собираться,
    /// но не сдвигают экран.
    private var frozenEntries: [CoreLogEntry]?

    private init() {}

    // MARK: - Запись

    func log(_ level: CoreLogLevel, _ source: CoreLogSource, _ message: String) {
        entries.append(
            CoreLogEntry(date: Date(), level: level, source: source, message: message)
        )

        if entries.count > capacity {
            entries.removeFirst(entries.count - capacity)
        }
    }

    func clear() {
        entries.removeAll()
        frozenEntries = nil
    }

    func togglePause() {
        if isPaused {
            isPaused = false
            frozenEntries = nil
            log(.info, .app, "лог-поток возобновлён")
        } else {
            log(.info, .app, "лог-поток приостановлен")
            isPaused = true
            frozenEntries = entries
        }
    }

    // MARK: - Выборка

    /// Записи с учётом паузы, фильтра по уровню и поиска.
    var visibleEntries: [CoreLogEntry] {
        var result = frozenEntries ?? entries

        if let selectedLevel {
            result = result.filter { $0.level >= selectedLevel }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { entry in
                entry.message.localizedCaseInsensitiveContains(query)
                    || entry.source.rawValue.localizedCaseInsensitiveContains(query)
                    || entry.level.rawValue.localizedCaseInsensitiveContains(query)
            }
        }

        return result
    }

    var plainText: String {
        visibleEntries
            .map { "\($0.timeString) \($0.level.label) \($0.source.tag) \($0.message)" }
            .joined(separator: "\n")
    }
}
