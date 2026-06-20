import os
import SwiftUI
import SwiftData

@main
struct SustenanceApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

enum ModelContainerFactory {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.draftandform.sustenance",
        category: "ModelContainer"
    )

    private static let schema = Schema([
        Recipe.self,
        PantryItem.self,
        SafetyProfile.self,
        MealLogEntry.self,
        ShoppingListItem.self,
    ])

    static func make() throws -> ModelContainer {
        let cloudConfiguration = makeConfiguration(storeName: "Sustenance.store", cloudKit: true)
        let localConfiguration = makeConfiguration(storeName: "SustenanceLocal.store", cloudKit: false)

        if let container = openStore(using: cloudConfiguration, label: "iCloud store") {
            AppPreferences.isUsingLocalStoreOnly = false
            return container
        }

        logger.warning("iCloud store unavailable; clearing and retrying.")
        resetStore(for: cloudConfiguration)

        if let container = openStore(using: cloudConfiguration, label: "iCloud store after reset") {
            AppPreferences.isUsingLocalStoreOnly = false
            return container
        }

        logger.warning("iCloud store still unavailable; falling back to local-only storage.")

        if let container = openStore(using: localConfiguration, label: "Local store") {
            AppPreferences.isUsingLocalStoreOnly = true
            return container
        }

        resetStore(for: localConfiguration)

        if let container = openStore(using: localConfiguration, label: "Local store after reset") {
            AppPreferences.isUsingLocalStoreOnly = true
            return container
        }

        throw NSError(
            domain: "ModelContainer",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "No local store could be opened."]
        )
    }

    static func resetAllStores() {
        resetStore(for: makeConfiguration(storeName: "Sustenance.store", cloudKit: true))
        resetStore(for: makeConfiguration(storeName: "SustenanceLocal.store", cloudKit: false))
    }

    private static func openStore(using configuration: ModelConfiguration, label: String) -> ModelContainer? {
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            logger.error("Failed to open \(label, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private static func makeConfiguration(storeName: String, cloudKit: Bool) -> ModelConfiguration {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        let storeURL = supportDirectory.appending(path: storeName)

        if cloudKit {
            return ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .private(AppConfiguration.cloudKitContainerIdentifier)
            )
        }

        return ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
    }

    private static func resetStore(for configuration: ModelConfiguration) {
        let fileManager = FileManager.default
        var urls: [URL] = []

        urls.append(contentsOf: relatedStoreURLs(for: configuration.url))

        if let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            urls.append(contentsOf: relatedStoreURLs(for: supportDirectory.appending(path: "default.store")))
            urls.append(contentsOf: relatedStoreURLs(for: supportDirectory.appending(path: "Nourish.store")))
        }

        for storeURL in urls where fileManager.fileExists(atPath: storeURL.path) {
            try? fileManager.removeItem(at: storeURL)
        }
    }

    private static func relatedStoreURLs(for url: URL) -> [URL] {
        [
            url,
            URL(fileURLWithPath: url.path + "-shm"),
            URL(fileURLWithPath: url.path + "-wal"),
        ]
    }
}

struct DataStoreStartupErrorView: View {
    let message: String
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(SustenanceTheme.accent)
                .accessibilityHidden(true)

            Text("Could not load your data")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Reset local data and try again", action: onReset)
                .buttonStyle(.borderedProminent)
                .tint(SustenanceTheme.accent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SustenanceTheme.background)
    }
}
