//
//  ContentView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var projectManager = ProjectManager.shared
    @State private var selectedFileURL: URL?
    @State private var fileContent: String = ""
    @State private var fileError: String?
    @State private var isLoading: Bool = false
    @State private var showRawMarkdown: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Project Progress Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Reads markdown files for project tracking")
                .font(.title2)
                .foregroundColor(.secondary)
            
            if !projectManager.projects.isEmpty {
                HStack {
                    // Project sidebar
                    ProjectListView(projectManager: projectManager)
                        .frame(width: 250)
                    
                    // Main content area
                    VStack {
                        if let activeProject = projectManager.activeProject {
                            VStack(spacing: 10) {
                                Text("Selected File:")
                                    .font(.headline)
                                Text(activeProject.filename)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                HStack {
                                    Text("Completion: \(Int(activeProject.completionPercentage))%")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    if activeProject.isSaving {
                                        Text("Saving...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else if let lastSaveTime = activeProject.lastSaveTime {
                                        Text("Saved at \(formatTime(lastSaveTime))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Button("Add New File") {
                                    selectMarkdownFile()
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // File content display area
                            VStack {
                                ContentListView(document: activeProject)
                                
                                Spacer(minLength: 20)
                                
                                // Collapsible Raw Markdown Section
                                VStack {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showRawMarkdown.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text("Raw Markdown Content")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Image(systemName: showRawMarkdown ? "chevron.down" : "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.vertical, 4)
                                    
                                    if showRawMarkdown {
                                        ScrollView {
                                            Text(fileContent)
                                                .font(.body.monospaced())
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding()
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: 200)
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(8)
                                        .transition(.opacity.combined(with: .scale(scale: 1.0, anchor: .top)))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack {
                    Button("Select Markdown File") {
                        selectMarkdownFile()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Text("No projects loaded. Add a markdown file to get started.")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Spacer()
            }
            
            if let fileError = fileError {
                Text(fileError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            // Configure window properties
            if let window = NSApplication.shared.windows.first {
                window.minSize = NSSize(width: 800, height: 600)
                // Remove fullscreen capability
                window.styleMask.remove(.fullScreen)
                // Also prevent fullscreen through collection behavior
                window.collectionBehavior.remove(.fullScreenPrimary)
            }
        }
        .onChange(of: projectManager.activeProject?.id) { newID in
            if let newID = newID,
               let project = projectManager.projects.first(where: { $0.id == newID }) {
                updateFileContent(for: project)
            } else {
                fileContent = ""
            }
        }
    }
    
    private func selectMarkdownFile() {
        fileError = nil
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["md", "markdown", "txt"] // Allow .md, .markdown, and .txt files
        panel.prompt = "Select"
        
        // Set default directory to user's documents
        panel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        if panel.runModal() == .OK {
            if let selectedURL = panel.url {
                // Validate that the file exists and is readable
                if FileManager.default.isReadableFile(atPath: selectedURL.path) {
                    // Check if it's a markdown file based on extension
                    let fileExtension = selectedURL.pathExtension.lowercased()
                    if fileExtension == "md" || fileExtension == "markdown" {
                        // Check if project is already loaded
                        if projectManager.isProjectLoaded(with: selectedURL) {
                            fileError = "This project is already loaded."
                            return
                        }
                        
                        selectedFileURL = selectedURL
                        loadFileContent(from: selectedURL)
                    } else {
                        fileError = "Please select a markdown file (.md or .markdown)."
                    }
                } else {
                    fileError = "Selected file is not readable."
                }
            }
        }
    }
    
    private func loadFileContent(from url: URL) {
        isLoading = true
        fileError = nil
        
        DispatchQueue.main.async {
            do {
                // Read the file content with UTF-8 encoding
                let content = try String(contentsOf: url, encoding: .utf8)
                self.fileContent = content
                let parsedItems = MarkdownParser.shared.parse(content)
                
                // Create new document
                let document = Document()
                document.loadItems(parsedItems, filename: url.lastPathComponent, fileURL: url)
                
                // Add to project manager
                self.projectManager.addProject(document)
                self.projectManager.setActiveProject(document)
                
                // Print the actual document content after all processing is complete
                self.printDocumentContent(document: document, filename: url.lastPathComponent)
                self.isLoading = false
            } catch {
                self.fileError = "Failed to read file: \(error.localizedDescription)"
                self.fileContent = ""
                self.isLoading = false
            }
        }
    }
    
    private func updateFileContent(for document: Document) {
        guard let fileURL = document.fileURL else { return }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            self.fileContent = content
        } catch {
            self.fileError = "Failed to read file: \(error.localizedDescription)"
            self.fileContent = ""
        }
    }
    
    private func printDocumentContent(document: Document, filename: String) {
        print("=== Document Content After Processing for \(filename) ===")
        for (index, item) in document.items.enumerated() {
            switch item.type {
            case .header:
                print("  \(index): Header (level \(item.level)): \(item.text) [ID: \(item.id)]")
            case .checkbox:
                print("  \(index): Checkbox (\(item.isChecked ? "checked" : "unchecked")): \(item.text) [ID: \(item.id)]")
            case .text:
                print("  \(index): Text: \(item.text) [ID: \(item.id)]")
            }
        }
        print("Final Completion: \(document.completionPercentage)%")
        print("Total Checkboxes: \(document.checkboxItems.count)")
        print("Checked Checkboxes: \(document.checkedItems.count)")
        print("========================================================")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}