//
//  ProjectRowView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct ProjectRowView: View {
    let document: Document
    let sortOption: SortOption
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(document.filename)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack(spacing: 4) {
                    Text("\(Int(document.completionPercentage))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(nsColor: .labelColor))

                    if let dateString = formattedDateString {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(dateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isActive ? 1.0 : 0.0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var formattedDateString: String? {
        var dateToShow: Date?
        var prefix = ""

        switch sortOption {
        case .date:
            dateToShow = document.fileModificationDate
            prefix = "Modified"
        case .lastAccessed:
            dateToShow = document.lastAccessedDate
            prefix = "Accessed"
        case .lastChecked:
            dateToShow = document.lastCheckedDate
            prefix = "Checked"
        case .name:
            // When sorting by name, showing the last checked date is a sensible default
            dateToShow = document.lastCheckedDate
            prefix = "Checked"
        }

        guard let date = dateToShow else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a" // e.g., "Oct 11, 9:52 PM"
        return "\(prefix) \(formatter.string(from: date))"
    }
}

#Preview {
    let document = Document()
    document.filename = "Sample Project.md"
    document.lastCheckedDate = Date()
    return ProjectRowView(
        document: document,
        sortOption: .lastChecked,
        isActive: true,
        onTap: {},
        onClose: {}
    )
}