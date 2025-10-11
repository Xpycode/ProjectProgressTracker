//
//  FileWatcher.swift
//  ProjectProgressTracker
//
//  Created by Gemini on 11.10.25.
//

import Foundation

class FileWatcher {
    private var dispatchSource: DispatchSourceFileSystemObject?
    private let fileURL: URL
    private let onFileChanged: () -> Void

    init(fileURL: URL, onFileChanged: @escaping () -> Void) {
        self.fileURL = fileURL
        self.onFileChanged = onFileChanged
    }

    func start() {
        guard dispatchSource == nil else { return }

        let fileDescriptor = open(fileURL.path, O_EVTONLY)
        guard fileDescriptor != -1 else { return }

        let source = Dispatch.makeDispatchSourceFileSystemObject(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.onFileChanged()
        }

        source.setCancelHandler {
            close(fileDescriptor)
        }

        source.resume()
        self.dispatchSource = source
    }

    func stop() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }

    deinit {
        stop()
    }
}
