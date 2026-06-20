import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query private var profiles: [SafetyProfile]

    @State private var allergies: [String] = []
    @State private var intolerances: [String] = []
    @State private var sensoryAvoids: [String] = []
    @State private var dietPreferences: Set<DietPreference> = []
    @State private var defaultEnergy: EnergyLevel = .okay
    @State private var hasDefaultEnergy = false
    @State private var didLoad = false
    @State private var iCloudAccountState: ICloudAccountStatus.AccountState = .unavailable("Checking iCloud…")
    @State private var showClearTestDataConfirmation = false
    @State private var clearTestDataErrorMessage: String?
    @State private var isShowingOnboarding = false

    @AppStorage(AppPreferences.appearanceModeKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage(AppPreferences.repeatMealRemindersEnabledKey) private var repeatMealRemindersEnabled = true

    var body: some View {
        NavigationStack {
            SustenanceScreenBackground(asset: .settings, style: .inlineHero) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        SustenanceInlineHero(asset: .settings)

                        intro
                        appearanceSection
                        helpSection
                        defaultEnergySection
                        mealTrackingSection

                        TagListEditor(
                            title: "Allergies",
                            caption: "Never suggest recipes containing these.",
                            tags: $allergies
                        )

                        DietPreferencesEditor(selected: $dietPreferences)

                        TagListEditor(
                            title: "Intolerances",
                            caption: "Warn with caution — not always excluded.",
                            tags: $intolerances
                        )

                        TagListEditor(
                            title: "Sensory avoids",
                            caption: "Warn and deprioritize when possible.",
                            tags: $sensoryAvoids
                        )

                        syncSection
                        testingSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.visible)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear {
                loadProfile()
                refreshICloudStatus()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshICloudStatus()
                }
            }
            .onChange(of: allergies) { _, _ in saveIfLoaded() }
            .onChange(of: dietPreferences) { _, _ in
                AppPreferences.hasCustomizedDietPreferences = true
                saveIfLoaded()
            }
            .onChange(of: intolerances) { _, _ in saveIfLoaded() }
            .onChange(of: sensoryAvoids) { _, _ in saveIfLoaded() }
            .onChange(of: defaultEnergy) { _, _ in saveIfLoaded() }
            .onChange(of: hasDefaultEnergy) { _, _ in saveIfLoaded() }
            .confirmationDialog(
                "Clear test data?",
                isPresented: $showClearTestDataConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear test data", role: .destructive, action: clearTestData)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes sample recipes, pantry items, meal history, shopping list, and resets your safety profile. This also syncs to iCloud.")
            }
            .alert(
                "Could not clear data",
                isPresented: Binding(
                    get: { clearTestDataErrorMessage != nil },
                    set: { if !$0 { clearTestDataErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(clearTestDataErrorMessage ?? "")
            }
            .fullScreenCover(isPresented: $isShowingOnboarding) {
                FirstRunTipsView {
                    isShowingOnboarding = false
                }
            }
        }
        .tabItem {
            Label("Settings", systemImage: "gearshape")
        }
        .tag(6)
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Replay the first-run walkthrough for Today, Calendar, Pantry, and Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("View onboarding tips") {
                AppPreferences.resetFirstRunTips()
                isShowingOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .tint(SustenanceTheme.accent)
            .accessibilityHint("Opens the onboarding tips screen")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your safety profile")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text("Synced privately to your Apple ID via iCloud. Changes update Today’s suggestions immediately.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var defaultEnergySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Default energy")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Optional starting point for Today when you open the app.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Use a default energy level", isOn: $hasDefaultEnergy)

            if hasDefaultEnergy {
                EnergySelectorView(selection: $defaultEnergy, title: "Starting energy")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var mealTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal tracking")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Log meals in Calendar. Gentle nudges appear when you repeat the same food often, and you can turn them off per meal or entirely here.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Repeat meal reminders", isOn: $repeatMealRemindersEnabled)
                .accessibilityHint("Shows or hides reminders when you eat the same meal repeatedly")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Choose light, dark, or follow your iPhone setting.")
                .font(.caption)
                .foregroundStyle(.secondary)

            AppearanceModePicker(selection: $appearanceModeRaw)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sync")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Label("iCloud", systemImage: "icloud")
                .font(.subheadline.weight(.medium))

            Text(iCloudAccountState.message)
                .font(.caption)
                .foregroundStyle(.secondary)

            if iCloudAccountState.needsSignIn {
                Text("Open Settings → Apple Account → iCloud, sign in with your Apple ID, and make sure iCloud is on for this iPhone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open Settings app") {
                    ICloudAccountStatus.openSettingsApp()
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Opens the Settings app so you can sign in to iCloud")
            }

            if AppPreferences.isUsingLocalStoreOnly {
                Text("This device is using local storage only. After signing in to iCloud, quit and reopen Sustenance to start syncing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("iCloud sync. \(iCloudAccountState.message)")
    }

    private var testingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Testing")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Tools for clearing bundled sample content.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(AppConfiguration.versionLabel)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .accessibilityLabel("Installed build \(AppConfiguration.versionLabel)")

            Button("Clear test data", role: .destructive) {
                showClearTestDataConfirmation = true
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Removes sample recipes, pantry items, and meal history")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func loadProfile() {
        let profile = profiles.first ?? createProfile()
        allergies = profile.allergies
        intolerances = profile.intolerances
        sensoryAvoids = profile.sensoryAvoids
        dietPreferences = Set(profile.selectedDietPreferences)
        if let energy = profile.defaultEnergyLevel {
            hasDefaultEnergy = true
            defaultEnergy = energy
        } else {
            hasDefaultEnergy = false
            defaultEnergy = .okay
        }
        didLoad = true
    }

    private func createProfile() -> SafetyProfile {
        let profile = SafetyProfile()
        modelContext.insert(profile)
        try? modelContext.save()
        return profile
    }

    private func saveIfLoaded() {
        guard didLoad else { return }
        let profile = profiles.first ?? createProfile()
        profile.allergies = allergies
        profile.intolerances = intolerances
        profile.sensoryAvoids = sensoryAvoids
        profile.selectedDietPreferences = Array(dietPreferences)
        profile.defaultEnergyLevel = hasDefaultEnergy ? defaultEnergy : nil
        if hasDefaultEnergy {
            UserDefaults.standard.set(defaultEnergy.rawValue, forKey: AppPreferences.todayEnergyLevelKey)
        } else {
            UserDefaults.standard.removeObject(forKey: AppPreferences.todayEnergyLevelKey)
        }
        try? modelContext.save()
    }

    private func refreshICloudStatus() {
        Task {
            let state = await ICloudAccountStatus.fetch()
            iCloudAccountState = state
        }
    }

    private func clearTestData() {
        do {
            try AppDataReset.clearAllTestData(modelContext: modelContext)
            loadProfile()
        } catch {
            clearTestDataErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [SafetyProfile.self], inMemory: true)
}
