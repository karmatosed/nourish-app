import SwiftUI

struct TagListEditor: View {
    let title: String
    let caption: String
    @Binding var tags: [String]

    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if tags.isEmpty {
                Text("None added yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Add term", text: $draft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(addDraft)
                    .accessibilityLabel("\(title) term")

                SustenanceAddButton(accessibilityLabel: "Add term", style: .inline, action: addDraft)
                    .disabled(normalizedDraft == nil)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.subheadline)

            Button {
                tags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(tag)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(SustenanceTheme.background)
        .overlay {
            Capsule()
                .strokeBorder(SustenanceTheme.border, lineWidth: 1)
        }
        .clipShape(Capsule())
    }

    private var normalizedDraft: String? {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !value.isEmpty else { return nil }
        guard !tags.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) else { return nil }
        return value
    }

    private func addDraft() {
        guard let value = normalizedDraft else { return }
        tags.append(value)
        draft = ""
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
