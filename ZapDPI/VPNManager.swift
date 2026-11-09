import Foundation
import Combine
import Network

/// Управление VPN-туннелем sing-box.
///
/// При бесплатной подписи Apple NetworkExtension (NEPacketTunnelProvider)
/// недоступен. В этом случае менеджер переходит в внутрипроцессный режим
/// (In-App Tun/Proxy), который работает без системного расширения.
@MainActor
final class VPNManager: ObservableObject {
    @Published private(set) var status: TunnelStatus = .disconnected
    @Published private(set) var signingType: SigningType = .unknown
    @Published private(set) var isUsingSystemVPN: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var localProxyPort: Int = 1080

    private var cancellables = Set<AnyCancellable>()
    private var connectTimer: Timer?
    private var config: AppConfig?

    init() {
        detectSigningType()
    }

    /// Определяет тип подписи (упрощённая заглушка).
    /// В реальном приложении проверяется профиль провижининга и доступность
    /// `NEPacketTunnelProvider` через `NEVPNManager`.
    private func detectSigningType() {
        // Заглушка: считаем, что используется бесплатная подпись
        // Реальная логика определения зависит от конфигурации Xcode / профиля
        signingType = .free
        isUsingSystemVPN = false

        if signingType.supportsSystemVPN {
            status = .disconnected
            isUsingSystemVPN = true
        } else {
            status = .disconnected
            isUsingSystemVPN = false
        }
    }

    /// Подключение VPN
    func connect(config: AppConfig) {
        self.config = config
        errorMessage = nil

        guard signingType.supportsSystemVPN else {
            // Бесплатная подпись — внутрипроцессный режим
            startInAppMode(config: config)
            return
        }

        // Системный VPN через NetworkExtension (заглушка)
        status = .connecting
        connectTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.status = .connected
            }
        }
    }

    /// Отключение VPN
    func disconnect() {
        connectTimer?.invalidate()
        connectTimer = nil

        status = .disconnecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.status = .disconnected
        }
    }

    /// Запуск внутрипроцессного режима (без NetworkExtension)
    private func startInAppMode(config: AppConfig) {
        status = .connecting

        // Имитация запуска локального туннеля/прокси внутри приложения
        connectTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.status = .connected
                self?.localProxyPort = 1080
            }
        }
    }

    /// Применение конфигурации к ядру sing-box (заглушка)
    func applyConfig(_ config: AppConfig) {
        self.config = config
        // В реальном приложении здесь вызывается API sing-box для перезагрузки конфига
        print("✅ Конфигурация применена: \(config.rawJSON.prefix(80))...")
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

import SwiftUI

extension Color {
    static let appBackground = Color(.systemGroupedBackground)
}
