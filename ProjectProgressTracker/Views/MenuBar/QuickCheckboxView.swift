//
//  QuickCheckboxView.swift
//  ProjectProgressTracker
//
//  Created by Alex on [[DATE]].
//

import SwiftUI

struct QuickCheckboxView: View {
    @ObservedObject var project: Document
    let item: ContentItem
    
    var body: some View {
        HStack(spacing: 6) {
            Button(action: {
                project.updateCheckbox(id: item.id, isChecked: !item.isChecked)
            }) {
                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isChecked ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(item.text)
                .font(.caption)
                .foregroundColor(item.isChecked ? .secondary : .primary)
                .strikethrough(item.isChecked)
                .lineLimit(2)
                .truncationMode(.tail)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}