import SwiftUI

struct FirstRunTip: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let message: String
}

enum FirstRunTips {
    static let items: [FirstRunTip] = [
        FirstRunTip(
            symbol: "bolt.circle",
            title: "Start with your energy",
            message: "On Today, pick Low, Okay, or Good. Suggestions adapt to how you feel right now."
        ),
        FirstRunTip(
            symbol: "checkmark.shield",
            title: "Set your safety profile",
            message: "Add allergies, intolerances, and diet preferences in Settings so suggestions stay safe."
        ),
        FirstRunTip(
            symbol: "basket",
            title: "Keep pantry honest",
            message: "Update Pantry with what you actually have. Missing ingredients show up on recipe cards."
        ),
        FirstRunTip(
            symbol: "calendar.badge.plus",
            title: "Log meals in Calendar",
            message: "Open Calendar, pick a day, and tap Log a meal. Type what you ate or pick a saved recipe."
        ),
        FirstRunTip(
            symbol: "trash",
            title: "Clear sample data anytime",
            message: "On the welcome screen or in Settings → Testing → Clear test data, remove bundled recipes and start fresh."
        ),
    ]
}

struct FirstRunTipsView: View {
    var onFinished: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    WelcomeIllustration(maxWidth: 220, maxHeight: 220)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    Text("A few things to know")
                        .font(.title2.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)

                    Text("Sustenance is built for low-energy days. Here’s a quick orientation.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(FirstRunTips.items) { tip in
                        tipRow(tip)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(SustenanceTheme.background)
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Got it") {
                        AppPreferences.hasSeenFirstRunTips = true
                        if let onFinished {
                            onFinished()
                        } else {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SustenanceTheme.background)
    }

    private func tipRow(_ tip: FirstRunTip) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: tip.symbol)
                .font(.title3)
                .foregroundStyle(SustenanceTheme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.headline)

                Text(tip.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tip.title). \(tip.message)")
    }
}

#Preview {
    FirstRunTipsView()
}
