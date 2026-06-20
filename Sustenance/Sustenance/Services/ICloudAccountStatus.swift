import CloudKit
import Foundation
import UIKit

enum ICloudAccountStatus {
    enum AccountState: Equatable {
        case available
        case noAccount
        case restricted
        case unavailable(String)

        var message: String {
            switch self {
            case .available:
                "Signed in. Your data syncs privately across devices using iCloud."
            case .noAccount:
                "Not signed in to iCloud on this iPhone."
            case .restricted:
                "iCloud is restricted on this device."
            case .unavailable(let detail):
                detail
            }
        }

        var needsSignIn: Bool {
            switch self {
            case .noAccount: true
            default: false
            }
        }
    }

    static func fetch() async -> AccountState {
        await withCheckedContinuation { continuation in
            let container = CKContainer(identifier: AppConfiguration.cloudKitContainerIdentifier)
            container.accountStatus { status, error in
                let state: AccountState
                if let error {
                    state = .unavailable(error.localizedDescription)
                } else {
                    switch status {
                    case .available:
                        state = .available
                    case .noAccount:
                        state = .noAccount
                    case .restricted:
                        state = .restricted
                    case .couldNotDetermine:
                        state = .unavailable("Could not check iCloud status.")
                    case .temporarilyUnavailable:
                        state = .unavailable("iCloud is temporarily unavailable.")
                    @unknown default:
                        state = .unavailable("Could not check iCloud status.")
                    }
                }
                continuation.resume(returning: state)
            }
        }
    }

    static func message(completion: @escaping (String) -> Void) {
        Task {
            let message = await fetch().message
            await MainActor.run {
                completion(message)
            }
        }
    }

    static func openSettingsApp() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
