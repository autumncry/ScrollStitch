import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct ScreenRecordingMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let originalExtension = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent("ScrollStitch-\(UUID().uuidString)")
                .appendingPathExtension(originalExtension)

            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }

            try FileManager.default.copyItem(at: received.file, to: copy)
            return ScreenRecordingMovie(url: copy)
        }
    }
}
