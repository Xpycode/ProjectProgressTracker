import SwiftUI

struct MenuBarPanelView: View {
    @ObservedObject var manager = ProjectManager.shared
    @State private var selectedProjectID: UUID?
    // If your ContentListView/row views use compact styling logic, good! Otherwise, add `.compact` parameter for font.
    
    var body: some View {
        VStack(spacing: 10) {
            // Header: Project selector and completion indicators
            HStack {
                Picker("Project", selection: $selectedProjectID) {
                    ForEach(manager.projects) { project in
                        HStack {
                            Text(project.filename)
                                .truncationMode(.tail)
                            Spacer()
                            Text("\(Int(project.completionPercentage))%")
                                .foregroundColor(.secondary)
                        }
                        .tag(project.id as UUID?)
                    }
                }
                .labelsHidden()
                .frame(width: 240)
                .pickerStyle(MenuPickerStyle())

                Spacer()
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Quit Project Progress Tracker")
            }
            .padding(.horizontal, 8)
            
            Divider()
            
            if let document = (manager.projects.first { $0.id == selectedProjectID } ?? manager.activeProject) {
                ContentListView(document: document) // standard, hierarchical, collapsible, checkboxes, etc.
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
            } else {
                Text("No project loaded.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .frame(width: 420, height: 410) // Wide, OnlySwitch style
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 8)
        .padding(.bottom, 8)
        // For best close-on-unfocus and correct anchoring, no NSPanel, use MenuBarExtra's .window style
    }
}