import SwiftUI

struct CompactHeaderRowView: View {
    let item: ContentItem
    
    var body: some View {
        Text(item.text)
            .font(.headline)
            .padding(.leading, CGFloat(item.indentationLevel * 12))
    }
}
