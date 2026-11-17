import Foundation

/// Статус VPN-туннеля
enum TunnelStatus: String, CaseIterable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error

    var displayName: String {
        switch self {
        case .disconnected: return "Отключено"
        case .connecting: return "Подключение..."
        case .connected: return "Подключено"
        case .disconnecting: return "Отключение..."
        case .error: return "Ошибка"
        }
    }

    var description: String { displayName }
}

/// Режим обхода DPI
enum DPIIntelligenceMode: String, CaseIterable, Identifiable {
    case none
    case fragmentation
    case tlsHelloModification
    case sniModification
    case packetDelay

    var id: String { rawValue }

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
        case .none:
            return "Стандартная маршрутизация без обхода DPI"
        case .fragmentation:
            return "Разделение пакетов на фрагменты для обхода анализа DPI"
        case .tlsHelloModification:
            return "Искажение TLS Client Hello для маскирования трафика"
        case .sniModification:
            return "Подмена имени сервера (SNI) в TLS-рукопожатии"
        case .packetDelay:
            return "Искусственная задержка пакетов для обхода Deep Packet Inspection"
        }
    }
}

/// DNS-резолверы
enum DNSOption: String, CaseIterable, Identifiable {
    case cloudflare
    case google
    case quad9
    case custom

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

/// Правило маршрутизации
struct RouteRule: Identifiable {
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

/// Конфигурация приложения / ядра
struct AppConfig {
    enum TunnelMode: String, CaseIterable {
        case system
        case inApp

        var displayName: String {
            switch self {
            case .system: return "Системный VPN (NEPacketTunnelProvider)"
            case .inApp: return "Внутрипроцессный (In-App Tun/Proxy)"
            }
        }
    }

    enum LogLevel: String, CaseIterable {
        case debug
        case info
        case warn
        case error
        case none

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

    var vpnEnabled: Bool = false
    var dpiBypassMode: DPIIntelligenceMode = .none
    var ipv6Enabled: Bool = false
    var dns: DNSOption = .cloudflare
    var customDNSServers: [String] = []
    var routes: [RouteRule] = [
        RouteRule(destination: "0.0.0.0/0", gateway: "vpn")
    ]
    var logLevel: LogLevel = .info
    var tunnelMode: TunnelMode = .system
    var rawJSON: String = AppConfig.defaultJSON

    static let defaultJSON = """
    {
      "log": {
        "level": "info"
      },
      "dns": {
        "servers": ["https://1.1.1.1/dns-query"]
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
        { "type": "direct", "tag": "direct" },
        { "type": "block", "tag": "block" }
      ],
      "route": {
        "rules": []
      }
    }
    """
}

/// Статистика трафика
struct TrafficStats {
    var incoming: UInt64 = 0
    var outgoing: UInt64 = 0
    var incomingSpeed: Double = 0
    var outgoingSpeed: Double = 0
    var sessionDuration: TimeInterval = 0
    var isConnected: Bool = false

    var incomingFormatted: String { Self.formatBytes(incoming) }
    var outgoingFormatted: String { Self.formatBytes(outgoing) }
    var incomingSpeedFormatted: String { Self.formatSpeed(incomingSpeed) }
    var outgoingSpeedFormatted: String { Self.formatSpeed(outgoingSpeed) }

    var durationFormatted: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private static func formatBytes(_ bytes: UInt64) -> String {
        if bytes < 1024 { return "\(bytes) Б" }
        if bytes < 1024 * 1024 { return String(format: "%.2f КБ", Double(bytes) / 1024.0) }
        if bytes < 1024 * 1024 * 1024 { return String(format: "%.2f МБ", Double(bytes) / 1024.0 / 1024.0) }
        return String(format: "%.2f ГБ", Double(bytes) / 1024.0 / 1024.0 / 1024.0)
    }

    private static func formatSpeed(_ bps: Double) -> String {
        if bps < 1024 { return String(format: "%.0f Б/с", bps) }
        if bps < 1024 * 1024 { return String(format: "%.2f КБ/с", bps / 1024.0) }
        return String(format: "%.2f МБ/с", bps / 1024.0 / 1024.0)
    }
}

/// Сохранённая конфигурация
struct SavedConfig: Identifiable {
    let id: UUID
    var name: String
    var fileName: String
    var isCurrent: Bool

    init(id: UUID = UUID(), name: String, fileName: String, isCurrent: Bool) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.isCurrent = isCurrent
    }
}
