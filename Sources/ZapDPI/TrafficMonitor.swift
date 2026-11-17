import Combine
import Foundation

/// Монитор трафика в реальном времени.
///
/// Показывает общий объём и текущую скорость входящего/исходящего трафика.
/// В реальном приложении значения должны браться из статистики туннеля.
final class TrafficMonitor: ObservableObject {
    @Published private(set) var stats = TrafficStats()
    @Published private(set) var isMonitoring: Bool = false

    private var timer: Timer?
    private var lastTick: Date?
    private var startedAt: Date?

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        startedAt = Date()
        lastTick = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false

        stats.incomingSpeed = 0
        stats.outgoingSpeed = 0
        stats.isConnected = false
    }

    func reset() {
        stats = TrafficStats()
        startedAt = nil
        lastTick = nil
    }

    private func tick() {
        let now = Date()
        let interval = max(now.timeIntervalSince(lastTick ?? now), 0.1)
        lastTick = now

        // Заглушка: имитация счётчиков от ядра sing-box / туннеля.
        let incomingDelta = UInt64.random(in: 0...2_000_000)
        let outgoingDelta = UInt64.random(in: 0...1_000_000)

        stats.incoming += incomingDelta
        stats.outgoing += outgoingDelta
        stats.incomingSpeed = Double(incomingDelta) / interval
        stats.outgoingSpeed = Double(outgoingDelta) / interval
        stats.isConnected = isMonitoring

        if let startedAt {
            stats.sessionDuration = now.timeIntervalSince(startedAt)
        }
    }
}
