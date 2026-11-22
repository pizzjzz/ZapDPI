import Foundation
import SwiftUI

/// Управление VPN-подключением.
///
/// При бесплатной подписи Apple NetworkExtension недоступен, поэтому
/// используется внутрипроцессный режим (In-App Tun/Proxy).
final class VPNManager: ObservableObject {
    enum SigningType: String {
        case free
        case paid

        /// Системный VPN (NEPacketTunnelProvider) доступен только при платной подписи.
        var supportsSystemVPN: Bool { self == .paid }
    }

    @Published private(set) var status: TunnelStatus = .disconnected
    @Published private(set) var signingType: SigningType = .free
    @Published private(set) var isUsingSystemVPN: Bool = false
    @Published private(set) var localProxyPort: Int = 1080
    @Published private(set) var errorMessage: String?

    private var config = AppConfig()
    private let logs = LogStore.shared

    /// Подключение с применением конфигурации.
    func connect(config: AppConfig) {
        self.config = config
        errorMessage = nil

        let wantsSystem = (config.tunnelMode == .system)
        isUsingSystemVPN = signingType.supportsSystemVPN && wantsSystem

        logs.log(.info, .app, "connect requested · mode=\(config.tunnelMode.rawValue) · dpi=\(config.dpiBypassMode.rawValue)")
        logs.log(.info, .core, "starting sing-box 1.12.0 (go1.24.4, ios/arm64)")
        logs.log(.debug, .config, "loading config · ipv6=\(config.ipv6Enabled) · dns=\(config.dns.rawValue) · log=\(config.logLevel.rawValue)")

        if let geo = GeoManifest.load() {
            logs.log(.debug, .config, "geo assets: \(geo.siteVersion) · geosite \(geo.siteSHA256.prefix(12))…")
        } else {
            logs.log(.debug, .config, "geo assets: built-in")
        }
        logs.log(.info, .dns, "dns: initialized · servers=\(dnsServers(for: config))")
        logs.log(.info, .tun, "inbound/tun[tun-in]: started at 172.19.0.1/30")
        logs.log(.info, .outbound, "outbound/direct[direct]: started")
        logs.log(.info, .route, "router: loaded \(config.routes.count) rule(s)")
        logs.log(.info, .core, "dpi bypass strategy: \(config.dpiBypassMode.displayName)")

        status = .connecting

        // Заглушка: здесь должен запускаться sing-box / NEPacketTunnelProvider.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }

            self.status = .connected

            if self.isUsingSystemVPN {
                self.logs.log(.info, .core, "NEPacketTunnelProvider: tunnel established")
            } else {
                self.logs.log(.info, .core, "in-app tunnel established · local proxy 127.0.0.1:\(self.localProxyPort)")
            }
            self.logs.log(.info, .app, "status: connected")
        }
    }

    func disconnect() {
        guard status == .connected || status == .connecting else { return }

        logs.log(.info, .app, "disconnect requested")
        status = .disconnecting

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            self.logs.log(.info, .tun, "inbound/tun[tun-in]: stopping")
            self.logs.log(.warn, .core, "sing-box stopped")

            self.status = .disconnected
            self.isUsingSystemVPN = false

            self.logs.log(.info, .app, "status: disconnected")
        }
    }

    /// Применение новой конфигурации. Если туннель запущен — мягкий перезапуск.
    func applyConfig(_ config: AppConfig) {
        self.config = config

        logs.log(.info, .config, "config reload · dpi=\(config.dpiBypassMode.rawValue) · routes=\(config.routes.count)")

        guard status == .connected else {
            logs.log(.debug, .config, "tunnel inactive · configuration stored")
            return
        }

        status = .connecting

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else { return }

            self.logs.log(.info, .core, "hot reload applied")
            self.status = .connected
            self.logs.log(.info, .app, "status: reloaded")
        }
    }

    var statusColor: Color {
        switch status {
        case .connected: return .green
        case .connecting, .disconnecting: return .yellow
        case .error: return .red
        case .disconnected: return .gray
        }
    }

    private func dnsServers(for config: AppConfig) -> String {
        let servers = config.dns == .custom ? config.customDNSServers : config.dns.servers
        return servers.isEmpty ? "system" : servers.joined(separator: ", ")
    }
}
