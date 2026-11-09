import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vpnManager: VPNManager
    @EnvironmentObject var trafficMonitor: TrafficMonitor
    @EnvironmentObject var configManager: ConfigManager

    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Контент вкладок
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                    .environmentObject(vpnManager)
                    .environmentObject(trafficMonitor)

                ConfigView()
                    .tag(Tab.config)
                    .environmentObject(configManager)
                    .environmentObject(vpnManager)

                SettingsView()
                    .tag(Tab.settings)
                    .environmentObject(configManager)
                    .environmentObject(vpnManager)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.appBackground)

            // Плавающий стеклянный таб-бар (Liquid Glass, iOS 18)
            LiquidGlassTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 34) // отступ под home indicator
        }
        .ignoresSafeArea(.keyboard)
        .alert(vpnManager.errorMessage ?? "", isPresented: .constant(vpnManager.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                vpnManager.errorMessage = nil
            }
        }
    }
}

enum Tab: Int, CaseIterable {
    case home
    case config
    case settings

    var icon: String {
        switch self {
        case .home: return "shield.fill"
        case .config: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .home: return "Главная"
        case .config: return "Config"
        case .settings: return "Настройки"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(VPNManager())
        .environmentObject(TrafficMonitor())
        .environmentObject(ConfigManager())
}
