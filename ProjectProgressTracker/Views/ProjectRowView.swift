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
                
                Text("\(Int(document.completionPercentage))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
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