import Foundation

/// Статус VPN-туннеля
enum TunnelStatus: String, CaseIterable, Codable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case disconnecting = "disconnecting"
    case error = "error"

    var displayName: String {
        switch self {
        case .disconnected: return "Отключено"
        case .connecting: return "Подключение..."
        case .connected: return "Подключено"
        case .disconnecting: return "Отключение..."
        case .error: return "Ошибка"
        }
    }

    var systemImage: String {
        switch self {
        case .disconnected: return "power"
        case .connecting: return "arrow.clockwise"
        case .connected: return "checkmark.seal.fill"
        case .disconnecting: return "arrow.clockwise"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

/// Метод обхода DPI
enum DPIIntelligenceMode: String, CaseIterable, Codable {
    case none = "none"
    case fragmentation = "fragmentation"
    case tlsHelloModification = "tls_hello_modification"
    case sniModification = "sni_modification"
    case packetDelay = "packet_delay"

    var displayName: String {
        switch self {
        case .none: return "Без обхода"
        case .fragmentation: return "Фрагментация пакетов"
        case .tlsHelloModification: return "Модификация TLS Client Hello"
        case .sniModification: return "Модификация SNI"
        case .packetDelay: return "Задержка пакетов"
        }
    }

    var description: String {
        switch self {
        case .none: return "Стандартная маршрутизация без обхода DPI"
        case .fragmentation: return "Разделение пакетов на фрагменты для обхода анализа DPI"
        case .tlsHelloModification: return "Искажение TLS Client Hello для маскирования трафика"
        case .sniModification: return "Подмена имени сервера (SNI) в TLS-рукопожатии"
        case .packetDelay: return "Искусственная задержка пакетов для обхода Deep Packet Inspection"
        }
    }
}

/// Опции DNS
enum DNSOption: String, CaseIterable, Codable, Identifiable {
    case cloudflare = "cloudflare"
    case google = "google"
    case quad9 = "quad9"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cloudflare: return "Cloudflare (1.1.1.1)"
        case .google: return "Google (8.8.8.8)"
        case .quad9: return "Quad9 (9.9.9.9)"
        case .custom: return "Свой DNS"
        }
    }

    var servers: [String] {
        switch self {
        case .cloudflare: return ["1.1.1.1", "1.0.0.1"]
        case .google: return ["8.8.8.8", "8.8.4.4"]
        case .quad9: return ["9.9.9.9", "149.112.112.112"]
        case .custom: return []
        }
    }
}

/// Конфигурация ядра sing-box / Xray-core
struct AppConfig: Codable {
    var version: String = "1.0.0"
    var vpnEnabled: Bool = false
    var tunnelMode: TunnelMode = .system
    var dpiBypassMode: DPIIntelligenceMode = .none
    var ipv6Enabled: Bool = false
    var dns: DNSOption = .cloudflare
    var customDNSServers: [String] = []
    var routes: [RouteRule] = []
    var logLevel: LogLevel = .info
    var rawJSON: String = """
    {
      "log": {
        "level": "info"
      },
      "dns": {
        "servers": [
          "https://1.1.1.1/dns-query"
        ]
      },
      "inbounds": [
        {
          "type": "tun",
          "tag": "tun-in",
          "address": ["172.19.0.1/30"],
          "autoRoute": true,
          "strictRoute": true
        }
      ],
      "outbounds": [
        {
          "type": "direct",
          "tag": "direct"
        },
        {
          "type": "block",
          "tag": "block"
        }
      ],
      "route": {
        "rules": []
      }
    }
    """

    enum TunnelMode: String, Codable, CaseIterable {
        case system = "system"
        case inApp = "in_app"

        var displayName: String {
            switch self {
            case .system: return "Системный VPN (NEPacketTunnelProvider)"
            case .inApp: return "Внутрипроцессный (In-App Tun/Proxy)"
            }
        }
    }

    enum LogLevel: String, Codable, CaseIterable {
        case debug = "debug"
        case info = "info"
        case warn = "warn"
        case error = "error"
        case none = "none"

        var displayName: String {
            switch self {
            case .debug: return "Отладка (Debug)"
            case .info: return "Информация (Info)"
            case .warn: return "Предупреждение (Warn)"
            case .error: return "Ошибка (Error)"
            case .none: return "Без логов"
            }
        }
    }
}

/// Правило маршрутизации
struct RouteRule: Codable, Identifiable {
    let id: UUID
    var destination: String
    var gateway: String
    var enabled: Bool

    init(id: UUID = UUID(), destination: String, gateway: String, enabled: Bool = true) {
        self.id = id
        self.destination = destination
        self.gateway = gateway
        self.enabled = enabled
    }
}

/// Статистика трафика
struct TrafficStats {
    var incoming: UInt64 = 0
    var outgoing: UInt64 = 0
    var incomingSpeed: Double = 0 // байт/сек
    var outgoingSpeed: Double = 0 // байт/сек
    var sessionDuration: TimeInterval = 0
    var isConnected: Bool = false

    var incomingFormatted: String {
        formatBytes(incoming)
    }

    var outgoingFormatted: String {
        formatBytes(outgoing)
    }

    var incomingSpeedFormatted: String {
        formatSpeed(incomingSpeed)
    }

    var outgoingSpeedFormatted: String {
        formatSpeed(outgoingSpeed)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        if bytes < 1024 { return "\(bytes) Б" }
        if bytes < 1024 * 1024 { return String(format: "%.2f КБ", Double(bytes) / 1024.0) }
        if bytes < UInt64(1024 * 1024 * 1024) { return String(format: "%.2f МБ", Double(bytes) / 1024.0 / 1024.0) }
        return String(format: "%.2f ГБ", Double(bytes) / 1024.0 / 1024.0 / 1024.0)
    }

    private func formatSpeed(_ bps: Double) -> String {
        if bps < 1024 { return String(format: "%.0f Б/с", bps) }
        if bps < 1024 * 1024 { return String(format: "%.2f КБ/с", bps / 1024.0) }
        return String(format: "%.2f МБ/с", bps / 1024.0 / 1024.0)
    }
}

/// Тип подписи Apple (влияет на доступность NetworkExtension)
enum SigningType: String, CaseIterable {
    case free = "free"       // Бесплатная (7 дней, без NetworkExtension)
    case paid = "paid"       // Платная (Apple Developer Program)
    case unknown = "unknown"

    var supportsSystemVPN: Bool {
        self == .paid
    }
}
