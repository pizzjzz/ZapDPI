import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vpnManager: VPNManager
    @EnvironmentObject var trafficMonitor: TrafficMonitor

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок приложения
                    VStack(spacing: 6) {
                        Text("ZapDPI")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Обход DPI и защита трафика")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)

                    // Статус подписи и режим VPN
                    signingInfoCard

                    // Монитор трафика
                    trafficMonitorCard

                    Spacer(minLength: 20)

                    // Кнопка VPN
                    vpnButton
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Карточка информации о подписи / режиме

    private var signingInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: vpnManager.signingType.supportsSystemVPN ? "checkmark.seal.fill" : "exclamationmark.triangle")
                    .foregroundStyle(vpnManager.signingType.supportsSystemVPN ? .green : .orange)
                Text(vpnManager.signingType.supportsSystemVPN
                     ? "Системный VPN активен"
                     : "Бесплатная подпись — внутрипроцессный режим")
                    .font(.headline)
                Spacer()
            }

            Text(vpnManager.signingType.supportsSystemVPN
                 ? "Используется NEPacketTunnelProvider (полный системный туннель)."
                 : "NetworkExtension недоступен. Приложение работает в локальном режиме In-App Tun/Proxy без системного VPN.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Карточка монитора трафика

    private var trafficMonitorCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Трафик")
                    .font(.headline)
                Spacer()
                Text(trafficMonitor.isMonitoring ? "Активно" : "Остановлено")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(trafficMonitor.isMonitoring ? .green : .secondary)
            }

            HStack(spacing: 20) {
                TrafficStatView(
                    title: "Входящий",
                    value: trafficMonitor.stats.incomingFormatted,
                    speed: trafficMonitor.stats.incomingSpeedFormatted,
                    icon: "arrow.down.circle.fill",
                    color: .blue
                )

                Divider()
                    .frame(height: 50)

                TrafficStatView(
                    title: "Исходящий",
                    value: trafficMonitor.stats.outgoingFormatted,
                    speed: trafficMonitor.stats.outgoingSpeedFormatted,
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
            }
            .padding(.vertical, 4)

            // Сессия
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Сессия: \(formatDuration(trafficMonitor.stats.sessionDuration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Кнопка VPN

    private var vpnButton: some View {
        Button {
            toggleVPN()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: vpnManager.status == .connected ? "stop.fill" : "power")
                    .font(.system(size: 28, weight: .semibold))

                Text(buttonTitle)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                ZStack {
                    if vpnManager.status == .connected {
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }

                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 34)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 34))
            .shadow(
                color: (vpnManager.status == .connected ? Color.red : Color.blue).opacity(0.35),
                radius: 16,
                x: 0,
                y: 8
            )
            .scaleEffect(vpnManager.status == .connecting || vpnManager.status == .disconnecting ? 0.97 : 1.0)
            .opacity(vpnManager.status == .connecting || vpnManager.status == .disconnecting ? 0.85 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(vpnManager.status == .connecting || vpnManager.status == .disconnecting)
    }

    private var buttonTitle: String {
        switch vpnManager.status {
        case .connected: return "Отключить VPN"
        case .connecting: return "Подключение..."
        case .disconnecting: return "Отключение..."
        case .disconnected: return "Включить VPN"
        case .error: return "Ошибка"
        }
    }

    private func toggleVPN() {
        if vpnManager.status == .connected {
            vpnManager.disconnect()
            trafficMonitor.stopMonitoring()
        } else {
            vpnManager.connect(config: configManager.currentConfig)
            trafficMonitor.startMonitoring()
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Поле одной статистики трафика
private struct TrafficStatView: View {
    let title: String
    let value: String
    let speed: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
            Text(speed)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HomeView()
        .environmentObject(VPNManager())
        .environmentObject(TrafficMonitor())
}
