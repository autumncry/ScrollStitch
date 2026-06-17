import Photos
import UIKit

enum PhotoLibraryWriter {
    static func save(_ image: UIImage) async throws {
        let status = await addOnlyAuthorizationStatus()
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryWriterError.notAuthorized
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: PhotoLibraryWriterError.saveFailed)
                }
            }
        }
    }

    private static func addOnlyAuthorizationStatus() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard current == .notDetermined else {
            return current
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}

enum PhotoLibraryWriterError: LocalizedError {
    case notAuthorized
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            "Photos permission is needed to save the long screenshot."
        case .saveFailed:
            "The image could not be saved to Photos."
        }
    }
}
