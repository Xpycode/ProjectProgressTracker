import SwiftUI

struct MenuBarPanelView: View {
    @ObservedObject var manager = ProjectManager.shared
    @State private var selectedProjectID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            if manager.projects.isEmpty {
                Spacer()
                Text("No project loaded.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                // Header: Project selector and completion percentage
                HStack(spacing: 8) {
                    Picker("Project", selection: $selectedProjectID) {
                        ForEach(manager.projects) { project in
                            Text(project.filename)
                                .truncationMode(.tail)
                                .tag(project.id as UUID?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(MenuPickerStyle())

                    Spacer()

                    if let document = manager.projects.first(where: { $0.id == selectedProjectID }) {
                        Text("\(String(format: "%.1f", document.completionPercentage))%")
                            .font(.body)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                if let document = manager.projects.first(where: { $0.id == selectedProjectID }) {
                    MenuBarFocusView(document: document)
                        .padding(12)
                }
            }
        }
        .frame(width: 380)
        .onAppear(perform: syncSelection)
        .onChange(of: manager.projects.map { $0.id }) { _, _ in syncSelection() }
        .onChange(of: selectedProjectID) { _, newID in
            if let newID = newID, let project = manager.projects.first(where: { $0.id == newID }) {
                manager.setActiveProject(project)
            }
        }
    }

    private func syncSelection() {
        // Ensure the selection is valid, defaulting to the first project if the active one is gone
        selectedProjectID = manager.activeProject?.id ?? manager.projects.first?.id
    }
}