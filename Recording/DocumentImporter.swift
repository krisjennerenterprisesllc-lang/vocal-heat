import SwiftUI
import UniformTypeIdentifiers

// Convenience UTType extensions for common audio types we need.
public extension UTType {
    // .m4a is MPEG-4 Audio; Apple defines "mpeg4Audio" (public.mpeg-4-audio)
    static var m4a: UTType {
        // Prefer the system-declared type if available
        if let t = UTType(filenameExtension: "m4a") {
            return t
        }
        return UTType("public.mpeg-4-audio") ?? .audio
    }

    // MP3 (public.mp3)
    static var mp3: UTType {
        if let t = UTType(filenameExtension: "mp3") {
            return t
        }
        return UTType("public.mp3") ?? .audio
    }
}

#if canImport(UIKit)
import UIKit

// A SwiftUI wrapper around UIDocumentPickerViewController that returns a picked file URL.
struct DocumentImporter: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIDocumentPickerViewController

    let allowedContentTypes: [UTType]
    let onCompletion: (Result<URL, Error>) -> Void

    init(allowedContentTypes: [UTType], onCompletion: @escaping (Result<URL, Error>) -> Void) {
        self.allowedContentTypes = allowedContentTypes
        self.onCompletion = onCompletion
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        controller.allowsMultipleSelection = false
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No-op
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onCompletion: (Result<URL, Error>) -> Void

        init(onCompletion: @escaping (Result<URL, Error>) -> Void) {
            self.onCompletion = onCompletion
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Treat cancel as a failure with a benign error
            onCompletion(.failure(NSError(domain: "DocumentImporter", code: NSUserCancelledError, userInfo: nil)))
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onCompletion(.failure(NSError(domain: "DocumentImporter", code: -1, userInfo: [NSLocalizedDescriptionKey: "No file selected"])))
                return
            }
            onCompletion(.success(url))
        }
    }
}

#else

// Fallback stub for platforms without UIKit (e.g., macOS app target without Catalyst, watchOS, tvOS where UIDocumentPicker isn’t available).
// Presenting this view will immediately report an unsupported-platform error to keep the build green.
struct DocumentImporter: View {
    let allowedContentTypes: [UTType]
    let onCompletion: (Result<URL, Error>) -> Void

    init(allowedContentTypes: [UTType], onCompletion: @escaping (Result<URL, Error>) -> Void) {
        self.allowedContentTypes = allowedContentTypes
        self.onCompletion = onCompletion
    }

    var body: some View {
        Color.clear
            .task {
                let err = NSError(
                    domain: "DocumentImporter",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Document importing is not supported on this platform."]
                )
                onCompletion(.failure(err))
            }
    }
}
#endif
