//
//  TextRowView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct TextRowView: View {
    let item: ContentItem
    
    var body: some View {
        Text(item.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .font(.body)
            .foregroundColor(.secondary)
            .padding(.leading, CGFloat(item.indentationLevel * 10 + 20))
    }
}

#Preview {
    TextRowView(item: ContentItem(type: .text, text: "Sample text content"))
}