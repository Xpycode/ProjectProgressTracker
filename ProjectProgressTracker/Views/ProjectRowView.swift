//
//  ProjectRowView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct ProjectRowView: View {
    let document: Document
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
                        .foregroundColor(.secondary)

                    if let lastChecked = document.lastCheckedDate {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("checked \(relativeTimeString(from: lastChecked))")
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
        .onTapGesture {
            onTap()
        }
    }

    private func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        let months = days / 30
        let years = days / 365

        if seconds < 60 {
            return "just now"
        } else if minutes < 60 {
            return minutes == 1 ? "1m ago" : "\(minutes)m ago"
        } else if hours < 24 {
            return hours == 1 ? "1h ago" : "\(hours)h ago"
        } else if days < 7 {
            return days == 1 ? "1d ago" : "\(days)d ago"
        } else if weeks < 4 {
            return weeks == 1 ? "1w ago" : "\(weeks)w ago"
        } else if months < 12 {
            return months == 1 ? "1mo ago" : "\(months)mo ago"
        } else {
            return years == 1 ? "1y ago" : "\(years)y ago"
        }
    }
}

#Preview {
    let document = Document()
    document.filename = "Sample Project.md"
    return ProjectRowView(
        document: document,
        isActive: true,
        onTap: {},
        onClose: {}
    )
}