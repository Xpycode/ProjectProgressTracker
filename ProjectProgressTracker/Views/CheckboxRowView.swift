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
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
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
        }
        .padding(.vertical, 0)
        .padding(.leading, CGFloat(item.indentationLevel * 8 + 12))
    }
}

#Preview {
    let document = Document()
    let item = ContentItem(
        type: .checkbox,
        text: "Sample task",
        isChecked: false,
        position: 0
    )
    return CheckboxRowView(document: document, item: item)
}