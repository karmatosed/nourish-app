import Foundation

enum AppConfiguration {
    static let cloudKitContainerIdentifier = "iCloud.com.draftandform.sustenance"

    static var versionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "Version \(version) (\(build))"
    }
}
