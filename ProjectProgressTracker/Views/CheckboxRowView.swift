//
//  CheckboxRowView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct CheckboxRowView: View {
    @ObservedObject var document: Document
    @EnvironmentObject var zoom: ZoomManager
    let item: ContentItem
    let isSelected: Bool
    
    /// Indentation per level in pixels
    private let indentPerLevel: CGFloat = 20

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            // Visual hierarchy indicator for nested items
            if item.indentationLevel > 0 {
                HStack(spacing: 0) {
                    ForEach(0..<item.indentationLevel, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)
                            .padding(.trailing, indentPerLevel - 1)
                    }
                }
                .frame(height: 20)
            }

            Button(action: {
                document.updateCheckbox(id: item.id, isChecked: !item.isChecked)
            }) {
                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isChecked ? .green : .secondary)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())

            // checkbox text:
            Text(item.text)
                .font(.system(size: 14 * zoom.scale, weight: .regular))
                .foregroundColor(item.isChecked ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.vertical, 1)

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

            if let dueDate = item.dueDate {
                Text(dueDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(dueDateColor(for: dueDate))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(dueDateColor(for: dueDate).opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 0)
        .padding(.leading, 12)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
    }

    private func dueDateColor(for date: Date) -> Color {
        if Calendar.current.isDateInToday(date) {
            return .orange
        }
        if date < Date() {
            return .red
        }
        return .secondary
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

#Preview {
    CheckboxRowView(
        document: Document(),
        item: ContentItem(
            type: .checkbox,
            text: "Sample task",
            isChecked: false,
            position: 0
        ),
        isSelected: false
    )
}