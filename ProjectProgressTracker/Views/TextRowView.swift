//
//  TextRowView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct TextRowView: View {
    @EnvironmentObject var zoom: ZoomManager
    let item: ContentItem
    
    var body: some View {
        Text(item.text)
            .font(.system(size: 13 * zoom.scale))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.leading, CGFloat(item.indentationLevel * 8 + 12))
    }
}

#Preview {
    TextRowView(item: ContentItem(type: .text, text: "Sample text content"))
}