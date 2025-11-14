//
//  ContentView.swift
//  ProjectProgressTracker
//
//  Created by simMAX on 29.08.25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var projectManager = ProjectManager.shared
    @EnvironmentObject var zoomManager: ZoomManager
    @State private var selectedFileURL: URL?
    @State private var fileContent: String = ""
    @State private var fileError: String?
    @State private var isLoading: Bool = false
    @State private var showRawMarkdown: Bool = false
    @State private var currentLoadID: UUID = UUID() // Track current file load operation
    
    var body: some View {
        VStack(spacing: 0) {
            // Remove the large title/subtitle area!
            if let activeProject = projectManager.activeProject {
                HStack {
                    // LEFT: Add New File button
                    Button(action: selectMarkdownFile) {
                        Label("Add New File", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    // CENTER: Completion status
                    Text("Completion: \(Int(activeProject.completionPercentage))%")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    // RIGHT: Zoom controls
                    HStack(spacing: 8) {
                        Button(action: { zoomManager.smaller() }) {
                            Image(systemName: "textformat.size.smaller")
                        }
                        .help("Decrease text size")

                        Button(action: { zoomManager.bigger() }) {
                            Image(systemName: "textformat.size.larger")
                        }
                        .help("Increase text size")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
                .overlay(Divider(), alignment: .bottom)
            }

            // Main area as before
            if !projectManager.projects.isEmpty {
                HStack {
                    // Project sidebar
                    ProjectListView(projectManager: projectManager)
                        .frame(width: 250)
                    
                    // Main content area, inject zoomManager as environment
                    VStack {
                        if let activeProject = projectManager.activeProject {
                            VStack {
                                ContentListView(document: activeProject)
                                    .environmentObject(zoomManager)
                                
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
        .onChange(of: projectManager.activeProject?.id) { _, newID in
            if let newID = newID,
               let project = projectManager.projects.first(where: { $0.id == newID }) {
                updateFileContent(for: project)
            } else {
                fileContent = ""
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { _ in
            selectMarkdownFile()
        }
    }
    
    private func selectMarkdownFile() {
        fileError = nil
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(importedAs: "net.daringfireball.markdown"), .plainText]
        panel.prompt = "Select"
        
        // Set default directory to user's documents
        panel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        if panel.runModal() == .OK {
            if let selectedURL = panel.url {
                // Validate that the file exists and is readable
                if FileManager.default.isReadableFile(atPath: selectedURL.path) {
                    // Check if it's a markdown file based on extension or content type
                    let fileExtension = selectedURL.pathExtension.lowercased()
                    let isMarkdownExtension = ["md", "markdown", "mdown", "mkd", "mkdn"].contains(fileExtension)

                    // Try content type check as secondary validation
                    let isMarkdownContentType: Bool
                    if let type = try? selectedURL.resourceValues(forKeys: [.contentTypeKey]).contentType {
                        isMarkdownContentType = type.conforms(to: UTType(importedAs: "net.daringfireball.markdown")) || type.conforms(to: .plainText)
                    } else {
                        isMarkdownContentType = false
                    }

                    if isMarkdownExtension || isMarkdownContentType {
                        // Check if project is already loaded
                        if projectManager.isProjectLoaded(with: selectedURL) {
                            fileError = "This project is already loaded."
                            return
                        }

                        selectedFileURL = selectedURL
                        loadFileContent(from: selectedURL)
                    } else {
                        fileError = "Please select a markdown file (.md, .markdown, etc.)."
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

        // Generate a new load ID to track this specific load operation
        let loadID = UUID()
        currentLoadID = loadID

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Read the file content with UTF-8 encoding
                let content = try String(contentsOf: url, encoding: .utf8)
                let parsedItems = MarkdownParser.shared.parse(content)

                // Create new document
                let document = Document()
                document.loadItems(parsedItems, filename: url.lastPathComponent, fileURL: url)

                DispatchQueue.main.async {
                    // Only update if this is still the most recent load request
                    guard self.currentLoadID == loadID else {
                        return // Discard outdated results
                    }

                    self.fileContent = content
                    // Add to project manager
                    self.projectManager.addProject(document)
                    self.projectManager.setActiveProject(document)
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    // Only update if this is still the most recent load request
                    guard self.currentLoadID == loadID else {
                        return // Discard outdated errors
                    }

                    self.fileError = "Failed to read file: \(error.localizedDescription)"
                    self.fileContent = ""
                    self.isLoading = false
                }
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}