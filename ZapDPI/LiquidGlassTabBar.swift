import SwiftUI

/// Плавающий стеклянный таб-бар в стиле Liquid Glass (iOS 18)
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(tab)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Стеклянный фон
                .ultraThinMaterial
                // Верхняя подсветка (край стёкла)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
                // Обводка для объёма
                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        Color.white.opacity(0.3),
                        lineWidth: 1
                    )
                    .padding(1)
            }
        )
        .background(
            // Мягкая тень под плавающим баром
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.black.opacity(0.12))
                .blur(radius: 24)
                .offset(y: 8)
                .padding(.horizontal, 6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
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
            VStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                    .symbolEffect(.bounce, value: selectedTab)
                Text(tab.title)
                    .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
            }
            .foregroundStyle(
                selectedTab == tab ? .primary : .secondary
            )
            .padding(.vertical, 8)
            .background(
                Group {
                    if selectedTab == tab {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(
                                color: Color.black.opacity(0.08),
                                radius: 10,
                                x: 0,
                                y: 4
                            )
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
        .background(Color(.systemGroupedBackground))
}
