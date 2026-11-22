import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var didLogStartup = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .config:
                    ConfigView()
                case .logs:
                    LogsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())

            LiquidGlassTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 8)
        }
        .onAppear {
            guard !didLogStartup else { return }
            didLogStartup = true
            LogStore.shared.log(.info, .app, "ZapDPI 1.0.0 started · logging enabled")
        }
        .onChange(of: selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}

enum Tab: Int, CaseIterable, Identifiable {
    case home
    case config
    case logs
    case settings

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .home: return "shield.fill"
        case .config: return "doc.text.fill"
        case .logs: return "terminal.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .home: return "Главная"
        case .config: return "Config"
        case .logs: return "Логи"
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
        .environmentObject(LogStore.shared)
}
