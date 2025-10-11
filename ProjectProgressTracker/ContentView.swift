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
    @EnvironmentObject private var zoomManager: ZoomManager
    @State private var selectedFileURL: URL?
    @State private var fileContent: String = ""
    @State private var fileError: String?
    @State private var isLoading: Bool = false
    @State private var sidebarWidth: CGFloat = 250

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            HStack {
                // LEFT: Add New File button
                Button(action: selectMarkdownFile) {
                    Label("Add New File", systemImage: "plus")
                }
                .buttonStyle(.bordered)

                Spacer()

                // CENTER: Progress bar (only if there's an active project)
                if let activeProject = projectManager.activeProject {
                    progressBarView(for: activeProject)
                }

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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(Divider(), alignment: .bottom)

            // Main content area
            if !projectManager.projects.isEmpty {
                HStack(spacing: 0) {
                    // Project sidebar
                    ProjectListView(projectManager: projectManager)
                        .frame(width: sidebarWidth)

                    // Resizer divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                        .overlay(
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 8)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let newWidth = sidebarWidth + value.translation.width
                                            sidebarWidth = min(max(newWidth, 200), 500)
                                        }
                                )
                                .onHover { hovering in
                                    if hovering {
                                        NSCursor.resizeLeftRight.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                        )

                    // Main content area, inject zoomManager as environment
                    VStack {
                        if let activeProject = projectManager.activeProject {
                            ContentListView(document: activeProject)
                                .environmentObject(zoomManager)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            } else {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No projects loaded")
                        .font(.title2)
                        .foregroundColor(.primary)

                    Text("Add a markdown file to get started.")
                        .foregroundColor(.secondary)
                        .font(.body)

                    Button(action: selectMarkdownFile) {
                        Label("Open Markdown File", systemImage: "plus.circle.fill")
                            .font(.body)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 8)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if let fileError = fileError {
                Text(fileError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .onReceive(NotificationCenter.default.publisher(for: .showRawMarkdown)) { _ in
            showRawMarkdownWindow()
        }
    }
    
    private func selectMarkdownFile() {
        fileError = nil

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [UTType(importedAs: "net.daringfireball.markdown"), .plainText]
        panel.prompt = "Select"

        // Set default directory to user's documents
        panel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        if panel.runModal() == .OK {
            let selectedURLs = panel.urls

            guard !selectedURLs.isEmpty else { return }

            var skippedCount = 0
            var loadedCount = 0

            for selectedURL in selectedURLs {
                // Validate that the file exists and is readable
                if FileManager.default.isReadableFile(atPath: selectedURL.path) {
                    // Check if it's a markdown file based on content type
                    if let type = try? selectedURL.resourceValues(forKeys: [.contentTypeKey]).contentType, type.conforms(to: UTType(importedAs: "net.daringfireball.markdown")) {
                        // Check if project is already loaded
                        if projectManager.isProjectLoaded(with: selectedURL) {
                            skippedCount += 1
                            continue
                        }

                        selectedFileURL = selectedURL
                        loadFileContent(from: selectedURL)
                        loadedCount += 1
                    } else {
                        fileError = "'\(selectedURL.lastPathComponent)' is not a markdown file."
                    }
                } else {
                    fileError = "'\(selectedURL.lastPathComponent)' is not readable."
                }
            }

            // Show summary if multiple files were selected
            if selectedURLs.count > 1 {
                if skippedCount > 0 {
                    fileError = "Loaded \(loadedCount) file(s), skipped \(skippedCount) already loaded."
                }
            } else if skippedCount > 0 {
                fileError = "This project is already loaded."
            }
        }
    }
    
    private func loadFileContent(from url: URL) {
        isLoading = true
        fileError = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Read the file content with UTF-8 encoding
                let content = try String(contentsOf: url, encoding: .utf8)
                let parsedItems = MarkdownParser.shared.parse(content)
                
                // Create new document
                let document = Document()
                document.loadItems(parsedItems, filename: url.lastPathComponent, fileURL: url)
                
                DispatchQueue.main.async {
                    self.fileContent = content
                    // Add to project manager
                    self.projectManager.addProject(document)
                    self.projectManager.setActiveProject(document)
                    
                    // Print the actual document content after all processing is complete
                    self.printDocumentContent(document: document, filename: url.lastPathComponent)
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
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

    private func showRawMarkdownWindow() {
        guard let activeProject = projectManager.activeProject,
              !fileContent.isEmpty else {
            return
        }

        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Raw Markdown: \(activeProject.filename)"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: RawMarkdownWindow(
                filename: activeProject.filename,
                content: fileContent
            )
        )
        window.makeKeyAndOrderFront(nil)
    }

    @ViewBuilder
    private func progressBarView(for document: Document) -> some View {
        // Gradient progress bar with percentage inside
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 200, height: 24)

            // Progress fill
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [.blue, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: CGFloat(document.completionPercentage / 100) * 200, height: 24)

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
            .frame(width: 200)
        }
        .frame(width: 200, height: 24)
        .animation(.easeInOut(duration: 0.3), value: document.completionPercentage)
    }
}

#Preview {
    ContentView()
}