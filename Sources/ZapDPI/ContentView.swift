import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .config:
                    ConfigView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())

            LiquidGlassTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 8)
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

extension Color {
    static let appBackground = Color(UIColor.systemGroupedBackground)
}

#Preview {
    ContentView()
        .environmentObject(VPNManager())
        .environmentObject(TrafficMonitor())
        .environmentObject(ConfigManager())
}
