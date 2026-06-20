import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct RecipeMarkdownImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var importedTitle: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Import a recipe from a Markdown file on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Expected format")
                        .font(.headline)

                    Text(sampleFormat)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SustenanceTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if let importedTitle {
                    Label("Imported “\(importedTitle)”", systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SustenanceTheme.safe)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(SustenanceTheme.unsafe)
                }

                Spacer()

                Button {
                    isImporting = true
                } label: {
                    Label("Choose Markdown file", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(SustenanceTheme.accent)
            }
            .padding(20)
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.plainText, UTType(filenameExtension: "md") ?? .plainText],
                allowsMultipleSelection: false
            ) { result in
                importFile(from: result)
            }
        }
    }

    private var sampleFormat: String {
        """
        # Soft Scrambled Eggs
        Time: 10 min
        Energy: low

        ## Ingredients
        - eggs — 2
        - salt

        ## Steps
        1. Whisk eggs with salt.
        2. Cook gently and serve.

        ## Notes
        Gentle protein for low-energy days.
        """
    }

    private func importFile(from result: Result<[URL], Error>) {
        errorMessage = nil
        importedTitle = nil

        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            importMarkdown(at: url)
        }
    }

    private func importMarkdown(at url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
            let parsed = try MarkdownRecipeParser.parse(markdown)
            let recipe = Recipe(
                title: parsed.title,
                ingredients: parsed.ingredients,
                steps: parsed.steps,
                notes: parsed.notes,
                prepTimeMinutes: parsed.prepTimeMinutes,
                requiredEnergy: parsed.requiredEnergy,
                isSafeMeal: parsed.isSafeMeal,
                isComfortMeal: parsed.isComfortMeal
            )
            modelContext.insert(recipe)
            try modelContext.save()
            importedTitle = parsed.title
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
