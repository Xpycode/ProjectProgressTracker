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
            Text("Projects (\(projectManager.projects.count))")
                .font(.headline)
                .padding(.bottom, 4)

            if projectManager.projects.isEmpty {
                Text("No projects loaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                List {
                    ForEach(projectManager.projects) { document in
                        ProjectRowView(
                            document: document,
                            isActive: projectManager.isActive(document),
                            onTap: {
                                projectManager.setActiveProject(document)
                            },
                            onClose: {
                                projectManager.removeProject(document)
                            }
                        )
                    }
                    .onMove(perform: projectManager.moveProject)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 200, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
    }
}

#Preview {
    ProjectListView(projectManager: ProjectManager.shared)
}