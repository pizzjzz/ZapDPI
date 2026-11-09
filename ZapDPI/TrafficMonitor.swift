import Foundation
import Combine

/// Монитор трафика в реальном времени.
/// Показывает общий объём и текущую скорость входящего/исходящего трафика.
final class TrafficMonitor: ObservableObject {
    @Published var stats = TrafficStats()
    @Published var isMonitoring: Bool = false

    private var timer: Timer?
    private var lastIncoming: UInt64 = 0
    private var lastOutgoing: UInt64 = 0
    private var lastUpdate: Date?

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastIncoming = 0
        lastOutgoing = 0
        lastUpdate = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func updateStats() {
        guard let lastUpdate = lastUpdate else { return }
        let now = Date()
        let interval = now.timeIntervalSince(lastUpdate)

        // Заглушка: имитация получения статистики от ядра sing-box / туннеля
        // В реальном приложении здесь читаются счётчики из NEPacketTunnelProvider
        // или локального встроенного туннеля.
        let simulatedIncoming = UInt64.random(in: 0...5_000_000)
        let simulatedOutgoing = UInt64.random(in: 0...3_000_000)

        let deltaIncoming = simulatedIncoming - lastIncoming
        let deltaOutgoing = simulatedOutgoing - lastOutgoing

        lastIncoming = simulatedIncoming
        lastOutgoing = simulatedOutgoing
        self.lastUpdate = now

        stats.incoming = simulatedIncoming
        stats.outgoing = simulatedOutgoing
        stats.incomingSpeed = Double(deltaIncoming) / max(interval, 0.1)
        stats.outgoingSpeed = Double(deltaOutgoing) / max(interval, 0.1)
        stats.sessionDuration = now.timeIntervalSince(lastUpdate)
        stats.isConnected = true
    }

    func reset() {
        stats = TrafficStats()
        lastIncoming = 0
        lastOutgoing = 0
    }
}
