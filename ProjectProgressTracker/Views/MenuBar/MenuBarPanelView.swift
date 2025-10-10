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
                // Header: Project selector and progress bar
                HStack(spacing: 12) {
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
                        progressBarView(for: document)
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

    @ViewBuilder
    private func progressBarView(for document: Document) -> some View {
        // Gradient progress bar with percentage inside
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 150, height: 24)

            // Progress fill
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [.blue, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: CGFloat(document.completionPercentage / 100) * 150, height: 24)

            // Percentage text (centered in container, not in fill)
            HStack {
                Spacer()
                Text("\(Int(document.completionPercentage))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .monospacedDigit()
                Spacer()
            }
            .frame(width: 150)
        }
        .frame(width: 150, height: 24)
        .animation(.easeInOut(duration: 0.3), value: document.completionPercentage)
    }
}