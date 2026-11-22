import SwiftUI

@main
struct ZapDPIApp: App {
    @StateObject private var vpnManager = VPNManager()
    @StateObject private var trafficMonitor = TrafficMonitor()
    @StateObject private var configManager = ConfigManager()
    @StateObject private var logStore = LogStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vpnManager)
                .environmentObject(trafficMonitor)
                .environmentObject(configManager)
                .environmentObject(logStore)
                .environmentObject(CoreUpdater.shared)
        }
    }
}
