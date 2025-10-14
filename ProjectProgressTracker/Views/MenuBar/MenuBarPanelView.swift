import SwiftUI

struct MenuBarPanelView: View {
    @ObservedObject var manager = ProjectManager.shared
    @State private var selectedProjectID: UUID?
    @State private var isProjectListExpanded = false

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
                    Button(action: {
                        if manager.projects.count > 1 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isProjectListExpanded.toggle()
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            if let currentProject = manager.projects.first(where: { $0.id == selectedProjectID }) {
                                Text(currentProject.filename)
                                    .truncationMode(.tail)
                                    .lineLimit(1)
                            }
                            if manager.projects.count > 1 {
                                Image(systemName: isProjectListExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(manager.projects.count <= 1)

                    Spacer()

                    if let document = manager.projects.first(where: { $0.id == selectedProjectID }) {
                        progressBarView(for: document)
                            .id(document.id)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .animation(.easeInOut(duration: 0.3), value: selectedProjectID)

                // Expanded project list
                if isProjectListExpanded && manager.projects.count > 1 {
                    VStack(spacing: 0) {
                        ForEach(manager.projects) { project in
                            Button(action: {
                                selectedProjectID = project.id
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isProjectListExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(project.filename)
                                        .truncationMode(.tail)
                                        .lineLimit(1)
                                    Spacer()
                                    if project.id == selectedProjectID {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(project.id == selectedProjectID ? Color.blue.opacity(0.1) : Color.clear)

                            if project.id != manager.projects.last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .transition(.opacity)
                }

                Divider()

                VStack {
                    if let document = manager.projects.first(where: { $0.id == selectedProjectID }) {
                        MenuBarFocusView(document: document)
                            .padding(12)
                            .id(document.id)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedProjectID)
            }
        }
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
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
                    .foregroundColor(document.completionPercentage >= 56 ? .white : .primary)
                    .shadow(color: document.completionPercentage >= 56 ? .black.opacity(0.3) : .clear, radius: 1, x: 0, y: 1)
                    .monospacedDigit()
                Spacer()
            }
            .frame(width: 150)
        }
        .frame(width: 150, height: 24)
        .animation(.easeInOut(duration: 0.5), value: document.completionPercentage)
    }
}