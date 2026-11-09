import SwiftUI

@main
struct ZapDPIApp: App {
    @StateObject private var vpnManager = VPNManager()
    @StateObject private var trafficMonitor = TrafficMonitor()
    @StateObject private var configManager = ConfigManager()

    init() {
        // Настройка внешнего вида приложения
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vpnManager)
                .environmentObject(trafficMonitor)
                .environmentObject(configManager)
                .onAppear {
                    // Запуск мониторинга трафика при старте
                    trafficMonitor.startMonitoring()
                }
        }
    }

    private func setupAppearance() {
        // Глобальный стиль навигации
        UINavigationBar.appearance().tintColor = .label
        UINavigationBar.appearance().backgroundColor = UIColor.systemGroupedBackground
    }
}
