import SwiftUI

/// Плавающий таб-бар приложения.
///
/// На iOS 26+ используется настоящий Liquid Glass (`glassEffect` +
/// `GlassEffectContainer`): капсулы вкладок сливаются в единую стеклянную
/// полосу, выбранная вкладка тонируется и реагирует на касания, а подсветка
/// морфится между вкладками. На более старых системах — матовый фолбэк.
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        if #available(iOS 26.0, *) {
            NativeGlassTabBar(selectedTab: $selectedTab)
        } else {
            LegacyTabBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - iOS 26+ Liquid Glass

@available(iOS 26.0, *)
private struct NativeGlassTabBar: View {
    @Binding var selectedTab: Tab

    @Namespace private var namespace

    private var selectionAnimation: Animation {
        .spring(response: 0.38, dampingFraction: 0.82)
    }

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(5)
        }
        .padding(.horizontal, 16)
        .animation(selectionAnimation, value: selectedTab)
    }

    private func tabButton(_ tab: Tab) -> some View {
        let isSelected = (selectedTab == tab)

        return Button {
            guard !isSelected else { return }
            withAnimation(selectionAnimation) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                    .contentTransition(.symbolEffect(.replace))

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected
                ? Glass.regular.tint(.blue).interactive()
                : Glass.regular.interactive(),
            in: .capsule
        )
        .glassEffectID(tab, in: namespace)
    }
}

// MARK: - iOS 17–25 fallback

private struct LegacyTabBar: View {
    @Binding var selectedTab: Tab

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(5)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedTab)
    }

    private func tabButton(_ tab: Tab) -> some View {
        let isSelected = (selectedTab == tab)

        return Button {
            guard !isSelected else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.white.opacity(0.16))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack {
            Spacer()
            LiquidGlassTabBar(selectedTab: .constant(.home))
                .padding(.bottom, 24)
        }
    }
}
