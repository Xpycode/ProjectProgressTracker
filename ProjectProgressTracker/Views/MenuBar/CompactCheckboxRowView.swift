import SwiftUI

struct CompactCheckboxRowView: View {
    @ObservedObject var document: Document
    let item: ContentItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Button(action: {
                document.updateCheckbox(id: item.id, isChecked: !item.isChecked)
            }) {
                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(item.text)
                .font(.body)
                .foregroundColor(item.isChecked ? .secondary : .primary)
                .strikethrough(item.isChecked)
        }
        .padding(.leading, CGFloat(item.indentationLevel * 12))
    }
}
