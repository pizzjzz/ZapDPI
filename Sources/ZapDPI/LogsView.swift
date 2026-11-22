import SwiftUI
import UIKit

struct LogsView: View {
    @EnvironmentObject private var logStore: LogStore
    @EnvironmentObject private var vpnManager: VPNManager

    @State private var showClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            header
            controls
            logList
        }
        .background(Color.appBackground.ignoresSafeArea())
        .confirmationDialog(
            "Очистить логи?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Очистить", role: .destructive) {
                logStore.clear()
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Логи ядра")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("·")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text("\(logStore.entries.count) записей")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var statusColor: Color {
        if logStore.isPaused { return .orange }
        switch vpnManager.status {
        case .connected: return .green
        case .connecting, .disconnecting: return .yellow
        case .error: return .red
        case .disconnected: return .gray
        }
    }

    private var statusText: String {
        if logStore.isPaused { return "поток приостановлен" }
        switch vpnManager.status {
        case .connected: return "sing-box работает"
        case .connecting: return "запуск ядра…"
        case .disconnecting: return "остановка ядра…"
        case .error: return "ошибка ядра"
        case .disconnected: return "ядро остановлено"
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 10) {
            searchField

            HStack(spacing: 8) {
                levelMenu
                Spacer(minLength: 0)
                iconButton(
                    systemName: logStore.isPaused ? "play.fill" : "pause.fill",
                    isActive: logStore.isPaused
                ) {
                    logStore.togglePause()
                }
                iconButton(
                    systemName: "arrow.down.to.line",
                    isActive: logStore.isAutoScrollEnabled
                ) {
                    logStore.isAutoScrollEnabled.toggle()
                }
                overflowMenu
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Поиск по логам", text: $logStore.searchText)
                .font(.system(size: 13, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !logStore.searchText.isEmpty {
                Button {
                    logStore.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var levelMenu: some View {
        Menu {
            Button {
                logStore.selectedLevel = nil
            } label: {
                if logStore.selectedLevel == nil {
                    Label("Все уровни", systemImage: "checkmark")
                } else {
                    Text("Все уровни")
                }
            }

            Divider()

            ForEach(CoreLogLevel.allCases) { level in
                Button {
                    logStore.selectedLevel = level
                } label: {
                    if logStore.selectedLevel == level {
                        Label(level.label, systemImage: "checkmark")
                    } else {
                        Text(level.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(logStore.selectedLevel?.color ?? Color.secondary)
                    .frame(width: 7, height: 7)

                Text(logStore.selectedLevel?.label ?? "ВСЕ")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
        }
    }

    private func iconButton(
        systemName: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? Color.blue : Color.primary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var overflowMenu: some View {
        Menu {
            ShareLink(item: logStore.plainText) {
                Label("Экспорт", systemImage: "square.and.arrow.up")
            }

            Button {
                UIPasteboard.general.string = logStore.plainText
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } label: {
                Label("Скопировать", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                showClearConfirmation = true
            } label: {
                Label("Очистить", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - List

    private var logList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if logStore.visibleEntries.isEmpty {
                        emptyState
                    } else {
                        ForEach(logStore.visibleEntries) { entry in
                            LogRow(entry: entry)
                                .id(entry.id)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .defaultScrollAnchor(.bottom)
            .contentMargins(.bottom, 104, for: .scrollContent)
            .onChange(of: logStore.visibleEntries.count) { _, _ in
                guard
                    logStore.isAutoScrollEnabled,
                    !logStore.isPaused,
                    let last = logStore.visibleEntries.last
                else { return }

                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "terminal")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.secondary)

            Text(logStore.entries.isEmpty ? "Логи пусты" : "Ничего не найдено")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(
                logStore.entries.isEmpty
                    ? "Подключите VPN на вкладке «Главная» — записи ядра появятся здесь."
                    : "Измените уровень или поисковый запрос."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 64)
    }
}

// MARK: - Row

private struct LogRow: View {
    let entry: CoreLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(entry.timeString)
                    .foregroundStyle(.tertiary)

                Text(entry.level.label)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.level.color)

                Text(entry.source.tag)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            Text(entry.message)
                .foregroundStyle(entry.level >= .warn ? entry.level.color : Color.primary)
        }
        .font(.system(size: 11.5, design: .monospaced))
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            entry.level >= .warn
                ? entry.level.color.opacity(0.07)
                : Color.clear
        )
        .textSelection(.enabled)
    }
}

// MARK: - Colors

extension CoreLogLevel {
    var color: Color {
        switch self {
        case .trace: return .secondary
        case .debug: return .teal
        case .info: return .blue
        case .warn: return .orange
        case .error: return .red
        case .fatal: return .purple
        }
    }
}

#Preview {
    LogsView()
        .environmentObject(LogStore.shared)
        .environmentObject(VPNManager())
}
