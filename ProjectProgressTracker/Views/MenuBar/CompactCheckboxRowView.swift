import SwiftUI

struct CompactCheckboxRowView: View {
    @ObservedObject var document: Document
    let item: ContentItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Button(action: {
                document.updateCheckbox(id: item.id, isChecked: !item.isChecked)
            }) {
                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(PlainButtonStyle())

            Text(item.text)
                .font(.body)
                .foregroundColor(item.isChecked ? .secondary : .primary)
                .strikethrough(item.isChecked)

            Spacer(minLength: 2)

            // Show child checkbox count if this checkbox has children
            if hasChildCheckboxes {
                Text(childProgressText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 0)
                    .background(Color.gray.opacity(0.13))
                    .cornerRadius(3)
            }
        }
        .padding(.leading, CGFloat(item.indentationLevel * 12))
    }

    // Check if this checkbox has child checkboxes underneath it
    private var hasChildCheckboxes: Bool {
        let stats = document.childCheckboxStats(for: item)
        return stats.total > 0
    }

    // Get the child progress text for display
    private var childProgressText: String {
        let stats = document.childCheckboxStats(for: item)
        return "\(stats.checked)/\(stats.total)"
    }
}
