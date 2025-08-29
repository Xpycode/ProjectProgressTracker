//
//  CheckboxRowView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct CheckboxRowView: View {
    @ObservedObject var document: Document
    let item: ContentItem
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Button(action: {
                print("DEBUG: Checkbox button clicked - ID: \(item.id), Current state: \(item.isChecked)")
                document.updateCheckbox(id: item.id, isChecked: !item.isChecked)
            }) {
                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isChecked ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(item.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(item.isChecked ? .secondary : .primary)
                .strikethrough(item.isChecked)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.leading, CGFloat(item.indentationLevel * 10 + 20))
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