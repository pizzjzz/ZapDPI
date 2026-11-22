import SwiftUI

struct CoreUpdateView: View {
    @EnvironmentObject private var updater: CoreUpdater

    var body: some View {
        List {
            coreSection
            geoSection
            automationSection

            if let release = updater.latestRelease, let body = release.body, !body.isEmpty {
                Section("Что нового в \(release.tagName)") {
                    notes(body)
                }
            }
        }
        .navigationTitle("Обновление ядра")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Ядро

    private var coreSection: some View {
        Section {
            HStack {
                Text("Встроенная версия")
                Spacer()
                Text(CoreInfo.bundledVersion)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Последняя версия")
                Spacer()
                Text(updater.latestRelease?.tagName ?? "—")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Статус")
                Spacer()
                statusLabel
            }

            Button {
                Task { await updater.checkForUpdates() }
            } label: {
                HStack(spacing: 8) {
                    if updater.coreState.isChecking {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(updater.coreState.isChecking ? "Проверка…" : "Проверить обновления")
                }
            }
            .disabled(updater.coreState.isChecking)

            if let release = updater.latestRelease {
                Link("Открыть релиз на GitHub", destination: release.htmlURL)
            }
        } header: {
            Text("Ядро sing-box")
        } footer: {
            Text(
                "iOS подписывает весь исполняемый код приложения, поэтому новый бинарник ядра нельзя "
                + "загрузить в рантайме. Версия сверяется с репозиторием \(CoreInfo.coreRepository); "
                + "новое ядро поставляется вместе со сборкой приложения, а geo-базы обновляются независимо."
            )
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch updater.coreState {
        case .idle:
            Text("не проверялось")
                .foregroundStyle(.secondary)
        case .checking:
            Text("проверка…")
                .foregroundStyle(.secondary)
        case .upToDate:
            Text("актуально")
                .foregroundStyle(.green)
        case .updateAvailable:
            Text("доступно \(updater.latestRelease?.tagName ?? "")")
                .foregroundStyle(.orange)
        case .failed(let message):
            Text(message)
                .foregroundStyle(.red)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Geo-базы

    private var geoSection: some View {
        Section {
            HStack {
                Text("Данные правил")
                Spacer()
                Text(updater.geoManifest == nil ? "встроенные" : "скачанные")
                    .foregroundStyle(.secondary)
            }

            if let manifest = updater.geoManifest {
                HStack {
                    Text("Версия правил")
                    Spacer()
                    Text("\(manifest.siteVersion) · \(manifest.ipVersion)")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Обновлено")
                    Spacer()
                    Text(Self.dateFormatter.string(from: manifest.updatedAt))
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task { await updater.updateGeoAssets() }
            } label: {
                HStack(spacing: 8) {
                    if updater.geoState.isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(updater.geoState.isUpdating ? "Загрузка…" : "Обновить geo-базы")
                }
            }
            .disabled(updater.geoState.isUpdating)

            switch updater.geoState {
            case .idle:
                EmptyView()
            case .updating:
                Text("Скачивание geosite.db и geoip.db…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .updated:
                Text("Geo-базы обновлены")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .failed(let message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Правила")
        } footer: {
            Text(
                "geosite.db и geoip.db скачиваются из релизов \(CoreInfo.geositeRepository) и "
                + "\(CoreInfo.geoipRepository) в Application Support. Их обновление не требует "
                + "переустановки приложения."
            )
        }
    }

    // MARK: - Автоматизация

    private var automationSection: some View {
        Section {
            Toggle("Проверять ядро при запуске", isOn: $updater.autoCheckEnabled)
            Toggle("Автообновление geo-баз", isOn: $updater.autoUpdateGeoEnabled)

            if let lastCheck = updater.lastCheck {
                HStack {
                    Text("Последняя проверка")
                    Spacer()
                    Text(Self.dateFormatter.string(from: lastCheck))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Автоматизация")
        } footer: {
            Text("Проверка ядра выполняется не чаще раза в 6 часов, geo-базы обновляются не чаще раза в неделю.")
        }
    }

    // MARK: - Release notes

    private func notes(_ markdown: String) -> some View {
        Group {
            if let attributed = try? AttributedString(
                markdown: markdown,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                Text(attributed)
            } else {
                Text(markdown)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()
}

#Preview {
    NavigationStack {
        CoreUpdateView()
            .environmentObject(CoreUpdater.shared)
    }
}
