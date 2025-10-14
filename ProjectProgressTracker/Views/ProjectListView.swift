//
//  ProjectListView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI

struct ProjectListView: View {
    @ObservedObject var projectManager: ProjectManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sort option buttons
            HStack {
                Spacer()
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        projectManager.selectSortOption(option)
                    }) {
                        HStack(spacing: 2) {
                            Text(option.rawValue)
                            if projectManager.sortOption == option {
                                Image(systemName: projectManager.sortAscending ? "arrow.up" : "arrow.down")
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(projectManager.sortOption == option ? .accentColor : .secondary)
                }
                Spacer()
            }
            .padding(.bottom, 4)

            if projectManager.projects.isEmpty {
                Text("No projects loaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(projectManager.sortedProjects) { document in
                        ProjectRowView(
                            document: document,
                            sortOption: projectManager.sortOption,
                            isActive: projectManager.isActive(document),
                            onTap: {
                                projectManager.setActiveProject(document)
                            },
                            onClose: {
                                projectManager.removeProject(document)
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding()
        .frame(minWidth: 200, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    let manager = ProjectManager.shared
    // Add some dummy data for preview
    let doc1 = Document()
    doc1.filename = "Project A"
    let doc2 = Document()
    doc2.filename = "Project B"
    manager.addProject(doc1)
    manager.addProject(doc2)
    
    return ProjectListView(projectManager: manager)
}