import SwiftUI

@main
struct ZapDPIApp: App {
    @StateObject private var vpnManager = VPNManager()
    @StateObject private var trafficMonitor = TrafficMonitor()
    @StateObject private var configManager = ConfigManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vpnManager)
                .environmentObject(trafficMonitor)
                .environmentObject(configManager)
                .onAppear {
                    trafficMonitor.startMonitoring()
                }
        }
    }
}
