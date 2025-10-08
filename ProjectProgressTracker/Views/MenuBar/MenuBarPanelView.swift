import SwiftUI

struct MenuBarPanelView: View {
    @ObservedObject var manager = ProjectManager.shared
    @State private var selectedProjectID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Project selector
            HStack {
                Picker("Project", selection: $selectedProjectID) {
                    ForEach(manager.projects) { project in
                        Text(project.filename)
                            .truncationMode(.tail)
                            .tag(project.id as UUID?)
                    }
                }
                .labelsHidden()
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            if let document = manager.projects.first(where: { $0.id == selectedProjectID }) {
                MenuBarFocusView(document: document)
                    .padding(12)
            } else {
                Spacer()
                Text("No project loaded.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .frame(width: 380)
        .onAppear {
            // Set the initial selection to the active project
            selectedProjectID = manager.activeProject?.id
        }
        .onChange(of: manager.activeProject?.id) { newID in
            // Keep the selection in sync with the manager
            selectedProjectID = newID
        }
        .onChange(of: selectedProjectID) { newID in
            // Update the manager when the user picks a new project
            if let newID = newID, let project = manager.projects.first(where: { $0.id == newID }) {
                manager.setActiveProject(project)
            }
        }
    }
}