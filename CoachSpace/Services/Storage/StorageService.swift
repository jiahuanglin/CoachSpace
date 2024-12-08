import Foundation
import FirebaseStorage
import UIKit

protocol StorageServiceProtocol {
    func uploadImage(_ image: UIImage, path: String, quality: CGFloat) async throws -> String
    func uploadFile(_ data: Data, path: String, metadata: StorageMetadata?) async throws -> String
    func downloadImage(from url: String) async throws -> UIImage
    func deleteImage(at path: String) async throws
    func generateThumbnail(for image: UIImage, size: CGSize) -> UIImage?
}

final class StorageService: StorageServiceProtocol {
    static let shared = StorageService()
    private let storage = Storage.storage()
    
    private init() {}
    
    func uploadImage(_ image: UIImage, path: String, quality: CGFloat = 0.8) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw StorageError.invalidImageData
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        return try await uploadFile(imageData, path: path, metadata: metadata)
    }
    
    func uploadFile(_ data: Data, path: String, metadata: StorageMetadata? = nil) async throws -> String {
        do {
            let ref = storage.reference().child(path)
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }
    
    func downloadImage(from url: String) async throws -> UIImage {
        guard let imageURL = URL(string: url) else {
            throw StorageError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            guard let image = UIImage(data: data) else {
                throw StorageError.invalidImageData
            }
            return image
        } catch {
            throw StorageError.downloadFailed(error)
        }
    }
    
    func deleteImage(at path: String) async throws {
        do {
            let ref = storage.reference().child(path)
            try await ref.delete()
        } catch {
            throw StorageError.deleteFailed(error)
        }
    }
    
    func generateThumbnail(for image: UIImage, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Helper Methods
    
    func getStoragePath(for type: StoragePathType, id: String) -> String {
        switch type {
        case .profileImage:
            return "users/\(id)/profile.jpg"
        case .classImage:
            return "classes/\(id)/cover.jpg"
        case .venueImage:
            return "venues/\(id)/cover.jpg"
        case .messageImage:
            return "messages/\(id)/image.jpg"
        case .custom(let path):
            return path
        }
    }
}

// MARK: - Types

enum StoragePathType {
    case profileImage
    case classImage
    case venueImage
    case messageImage
    case custom(String)
}

// MARK: - Errors

enum StorageError: LocalizedError {
    case invalidImageData
    case invalidURL
    case uploadFailed(Error)
    case downloadFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .invalidURL:
            return "Invalid URL"
        case .uploadFailed(let error):
            return "Failed to upload file: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Failed to download file: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete file: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func compressed(quality: CGFloat = 0.5) -> Data? {
        return jpegData(compressionQuality: quality)
    }
} 