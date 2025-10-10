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

            // Sort option buttons
            HStack(spacing: 4) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        projectManager.sortOption = option
                    }) {
                        Text(sortButtonLabel(for: option))
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(projectManager.sortOption == option ? Color.accentColor : Color.gray.opacity(0.2))
                            .foregroundColor(projectManager.sortOption == option ? .white : .primary)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom, 4)

            if projectManager.projects.isEmpty {
                Text("No projects loaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
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
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 200, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
    }

    private func sortButtonLabel(for option: SortOption) -> String {
        switch option {
        case .name:
            return "Name"
        case .date:
            return "Date"
        case .lastAccessed:
            return "Accessed"
        case .lastChecked:
            return "Checked"
        }
    }
}

#Preview {
    ProjectListView(projectManager: ProjectManager.shared)
}