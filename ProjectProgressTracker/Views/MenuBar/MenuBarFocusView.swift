import SwiftUI

struct MenuBarFocusView: View {
    @ObservedObject var document: Document
    
    private let numberOfNextItems = 5
    
    var body: some View {
        let (lastChecked, nextItems) = document.items(numberOfNextItems: numberOfNextItems)
        
        return VStack(alignment: .leading, spacing: 8) {
            if let lastChecked = lastChecked {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    CompactCheckboxRowView(document: document, item: lastChecked)
                }
                Divider()
            }
            
            if !nextItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(nextItems) { item in
                        if item.type == .header {
                            CompactHeaderRowView(item: item)
                        } else if item.type == .checkbox {
                            CompactCheckboxRowView(document: document, item: item)
                        }
                    }
                }
                Spacer() // Pushes all content to the top
            } else {
                // If there's no "last checked" and no "next items", it means the list is empty.
                if lastChecked == nil {
                    Spacer()
                    Text("No tasks in this project.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    // Otherwise, all tasks are complete.
                    Text("All tasks complete!")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                }
            }
        }
    }
}
