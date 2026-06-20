import SwiftUI
import SwiftData

struct WelcomeIllustration: View {
    var maxWidth: CGFloat = 380
    var maxHeight: CGFloat = 380

    var body: some View {
        SustenanceIllustrationStyle.styled(
            Image("WelcomeBackground")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: maxWidth, maxHeight: maxHeight),
            placement: .screenBackdrop
        )
        .accessibilityHidden(true)
    }
}

struct WelcomeLoadingView: View {
    var onRemoveSampleData: () -> Void
    var isRemoveSampleDataEnabled = true

    var body: some View {
        ZStack {
            WelcomeIllustration()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 24)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 10) {
                    Text("Sustenance")
                        .font(.system(.largeTitle, design: .default, weight: .semibold))
                        .foregroundStyle(SustenanceTheme.accent)
                        .accessibilityAddTraits(.isHeader)

                    Text("Meals for the energy you have.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()

                if isRemoveSampleDataEnabled {
                    Button("Remove sample data", action: onRemoveSampleData)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 12)
                        .accessibilityHint("Removes bundled recipes, pantry items, and meal history")
                }

                ProgressView()
                    .tint(SustenanceTheme.accent)
                    .padding(.bottom, 48)
                    .accessibilityLabel("Loading Sustenance")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SustenanceTheme.background)
    }
}

private enum LaunchStage: Equatable {
    case welcome
    case onboarding
    case main
    case failed(String)
}

@MainActor
private final class LaunchController: ObservableObject {
    @Published var stage: LaunchStage
    @Published var container: ModelContainer?

    private var launchTask: Task<Void, Never>?

    init() {
        if AppPreferences.hasSeenFirstRunTips {
            stage = .main
        } else {
            stage = .welcome
        }
    }

    func beginLaunchIfNeeded() {
        guard launchTask == nil else { return }

        if !AppPreferences.hasSeenFirstRunTips, stage == .main {
            stage = .welcome
        }

        launchTask = Task {
            await runLaunch()
            launchTask = nil
        }
    }

    func retryLaunch() {
        launchTask?.cancel()
        launchTask = nil
        ModelContainerFactory.resetAllStores()
        container = nil
        stage = .welcome
        beginLaunchIfNeeded()
    }

    private func runLaunch() async {
        if stage == .main, container != nil {
            return
        }

        if stage == .main, container == nil {
            stage = .welcome
        }

        guard stage == .welcome else { return }

        let welcomeStartedAt = ContinuousClock.now

        async let loadedContainer: ModelContainer? = loadContainer()

        let minimumWelcomeDuration: Duration = .seconds(3)
        let elapsed = ContinuousClock.now - welcomeStartedAt
        if elapsed < minimumWelcomeDuration {
            try? await Task.sleep(for: minimumWelcomeDuration - elapsed)
        }

        guard !Task.isCancelled else { return }

        var resolvedContainer = await loadedContainer

        if resolvedContainer == nil {
            ModelContainerFactory.resetAllStores()
            resolvedContainer = try? ModelContainerFactory.make()
        }

        guard let resolvedContainer else {
            stage = .failed("Sustenance could not open its local data store. Reset local data and try again.")
            return
        }

        container = resolvedContainer

        if AppPreferences.hasSeenFirstRunTips {
            stage = .main
        } else {
            stage = .onboarding
        }
    }

    private func loadContainer() async -> ModelContainer? {
        if let container {
            return container
        }

        return await Task.detached(priority: .userInitiated) {
            try? ModelContainerFactory.make()
        }.value
    }
}

struct AppRootView: View {
    @AppStorage(AppPreferences.appearanceModeKey) private var appearanceModeRaw = AppearanceMode.system.rawValue

    @StateObject private var launch = LaunchController()
    @State private var showClearSampleDataConfirmation = false
    @State private var clearSampleDataErrorMessage: String?

    private var preferredColorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceModeRaw)?.colorScheme
    }

    var body: some View {
        ZStack {
            switch launch.stage {
            case .welcome:
                WelcomeLoadingView(
                    onRemoveSampleData: { showClearSampleDataConfirmation = true },
                    isRemoveSampleDataEnabled: launch.container != nil
                )
            case .onboarding:
                FirstRunTipsView {
                    launch.stage = .main
                }
            case .main:
                if let container = launch.container {
                    ContentView()
                        .modelContainer(container)
                } else {
                    WelcomeLoadingView(onRemoveSampleData: {}, isRemoveSampleDataEnabled: false)
                }
            case .failed(let message):
                DataStoreStartupErrorView(message: message, onReset: launch.retryLaunch)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SustenanceTheme.background)
        .preferredColorScheme(preferredColorScheme)
        .confirmationDialog(
            "Remove sample data?",
            isPresented: $showClearSampleDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove sample data", role: .destructive, action: clearSampleData)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes sample recipes, pantry items, meal history, shopping list, and resets your safety profile.")
        }
        .alert(
            "Could not remove sample data",
            isPresented: Binding(
                get: { clearSampleDataErrorMessage != nil },
                set: { if !$0 { clearSampleDataErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(clearSampleDataErrorMessage ?? "")
        }
        .task {
            launch.beginLaunchIfNeeded()
        }
    }

    private func clearSampleData() {
        guard let container = launch.container else { return }

        do {
            try AppDataReset.clearAllTestData(modelContext: container.mainContext)
        } catch {
            clearSampleDataErrorMessage = error.localizedDescription
        }
    }
}

#Preview("Welcome") {
    WelcomeLoadingView(onRemoveSampleData: {})
}

#Preview("Root") {
    AppRootView()
}
