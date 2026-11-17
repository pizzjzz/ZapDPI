import SwiftUI

/// Плавающий стеклянный таб-бар в стиле Liquid Glass (iOS 18).
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedTab)
    }

    @ViewBuilder
    private func tabButton(_ tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                Text(tab.title)
                    .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
            }
            .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if selectedTab == tab {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LiquidGlassTabBar(selectedTab: .constant(.home))
        .padding()
        .background(Color.appBackground)
}
