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

    /// Подключение с применением конфигурации.
    func connect(config: AppConfig) {
        self.config = config
        errorMessage = nil

        let wantsSystem = (config.tunnelMode == .system)
        isUsingSystemVPN = signingType.supportsSystemVPN && wantsSystem

        status = .connecting

        // Заглушка: здесь должен запускаться sing-box / NEPacketTunnelProvider.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            self.status = .connected
        }
    }

    func disconnect() {
        guard status == .connected || status == .connecting else { return }
        status = .disconnecting

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.status = .disconnected
            self.isUsingSystemVPN = false
        }
    }

    /// Применение новой конфигурации. Если туннель запущен — мягкий перезапуск.
    func applyConfig(_ config: AppConfig) {
        self.config = config

        guard status == .connected else { return }
        status = .connecting

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else { return }
            self.status = .connected
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
}
