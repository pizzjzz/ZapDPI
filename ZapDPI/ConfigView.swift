import SwiftUI

struct ConfigView: View {
    @EnvironmentObject var configManager: ConfigManager
    @EnvironmentObject var vpnManager: VPNManager

    @State private var editJSON: String = ""
    @State private var isSaving = false
    @State private var showDPISettings = false
    @State private var showSaveConfirmation = false
    @State private var configName: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Заголовок
                VStack(alignment: .leading, spacing: 8) {
                    Text("Конфигурация ядра")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("Редактируйте JSON-конфигурацию sing-box / Xray-core")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .padding(.horizontal, 20)

                // Редактор JSON
                VStack(alignment: .leading, spacing: 8) {
                    Text("JSON конфиг")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)

                    TextEditor(text: $editJSON)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .textSelection(.enabled)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(minHeight: 260)
                }
                .padding(.horizontal, 20)

                // Настройки обхода DPI
                VStack(alignment: .leading, spacing: 12) {
                    Text("Обход DPI")
                        .font(.headline.weight(.semibold))
                        .padding(.horizontal, 20)

                    Picker("Режим обхода", selection: Binding(
                        get: { configManager.currentConfig.dpiBypassMode },
                        set: { configManager.currentConfig.dpiBypassMode = $0 }
                    )) {
                        ForEach(DPIIntelligenceMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 20)

                    Text(configManager.currentConfig.dpiBypassMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                }

                // Кнопка "Сохранить и применить"
                Button {
                    saveAndApply()
                } label: {
                    HStack(spacing: 10) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.icloud.fill")
                        }
                        Text("Сохранить и применить")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [Color.indigo, Color.indigo.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.indigo.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
                .opacity(isSaving ? 0.85 : 1.0)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Быстрые действия с конфигами
                VStack(alignment: .leading, spacing: 10) {
                    Text("Управление конфигами")
                        .font(.headline.weight(.semibold))
                        .padding(.horizontal, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ConfigActionButton(
                            title: "Новый конфиг",
                            icon: "doc.badge.plus",
                            color: .blue
                        ) {
                            configName = ""
                            showSaveConfirmation = true
                        }

                        ConfigActionButton(
                            title: "Импортировать",
                            icon: "arrow.down.doc",
                            color: .green
                        ) {
                            // Заглушка импорта
                        }

                        ConfigActionButton(
                            title: "Экспортировать",
                            icon: "square.and.arrow.up",
                            color: .orange
                        ) {
                            // Заглушка экспорта
                        }

                        ConfigActionButton(
                            title: "Сброс к дефолту",
                            icon: "arrow.counterclockwise",
                            color: .red
                        ) {
                            resetToDefault()
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color.appBackground)
        .onAppear {
            editJSON = configManager.currentConfig.rawJSON
        }
        .alert("Сохранить конфиг", isPresented: $showSaveConfirmation) {
            TextField("Название конфига", text: $configName)
            Button("Отмена", role: .cancel) {}
            Button("Сохранить") {
                saveConfigAs()
            }
        } message: {
            Text("Введите название для новой конфигурации")
        }
    }

    private func saveAndApply() {
        // Обновляем rawJSON из редактора
        configManager.currentConfig.rawJSON = editJSON

        isSaving = true

        // Применяем конфиг к ядру (с задержкой для визуального эффекта)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            vpnManager.applyConfig(configManager.currentConfig)
            isSaving = false
        }
    }

    private func saveConfigAs() {
        guard !configName.isEmpty else { return }
        do {
            try configManager.saveCurrentConfig(name: configName)
            configName = ""
        } catch {
            print("❌ Ошибка сохранения конфига: \(error)")
        }
    }

    private func resetToDefault() {
        configManager.currentConfig = AppConfig()
        editJSON = configManager.currentConfig.rawJSON
    }
}

/// Кнопка быстрого действия в сетке
private struct ConfigActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ConfigView()
        .environmentObject(ConfigManager())
        .environmentObject(VPNManager())
}
