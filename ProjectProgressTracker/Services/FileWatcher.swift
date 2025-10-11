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

        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.main
        )

        dispatchSource?.setEventHandler { [weak self] in
            self?.onFileChanged()
        }

        dispatchSource?.setCancelHandler {
            close(fileDescriptor)
        }

        dispatchSource?.resume()
    }

    func stop() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }

    deinit {
        stop()
    }
}
