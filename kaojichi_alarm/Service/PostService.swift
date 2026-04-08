//
//  PostInfoViewModel.swift
//  picture_alarm_app
//
//  Created by A S on 2025/09/15.
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct PostInfo: Identifiable {
    var id: String // Firebaseでの識別用
    var userId: String // ユーザーのID
    var postTime: Date? // 投稿時刻
    var imageUrl: String?
    var goodCount: Int = 0 // いいね数
    var comments: [String] = [] // コメント
    var user: User?
    var status:String? //ユーザーの起床状況
    var thumbnailUrl: String? // サムネイルURL
    var originalImagePath: String? // オリジナル画像のStorageパス
}

class PostService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func uploadPost(
        imageData: Data,
        comment: String?,
        status: UserStatus,
        originalImagePath: String? = nil,
        completion: @escaping (Error?) -> Void
    ) async throws {
        
        guard let currentUser = Auth.auth().currentUser else {
            completion(NSError(domain: "PostService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ユーザー未サインイン"]))
            return
        }
        
        let postRef = db.collection("posts").document()
        let storageRef = storage.reference().child("posts/\(postRef.documentID).jpg")

        // Compress image before upload
        guard let image = UIImage(data: imageData),
              let compressedData = image.jpegData(compressionQuality: 0.3) else {
            completion(NSError(domain: "PostService", code: -2, userInfo: [NSLocalizedDescriptionKey: "画像圧縮失敗"]))
            return
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public,max-age=3600"

        _ = try await storageRef.putDataAsync(compressedData, metadata: metadata)
        let url = try await storageRef.downloadURL()

        // Resize Images対応：サムネイルURLを取得、存在しなければフル画像を使用
        let thumbRef = storage.reference().child("thumbnails/\(postRef.documentID)_400x400.jpg")
        let thumbURL = try? await thumbRef.downloadURL()

        var post: [String: Any] = [
            "id": postRef.documentID,
            "userId": currentUser.uid,
            "postTime": FieldValue.serverTimestamp(),
            "imageUrl": url.absoluteString,
            "thumbnailUrl": thumbURL?.absoluteString ?? url.absoluteString,
            "goodCount": 0,
            "comments": [comment ?? ""],
            "status": status.rawValue
        ]
        
        if let originalImagePath, !originalImagePath.isEmpty {
            post["originalImagePath"] = originalImagePath
        }

        do {
            try await postRef.setData(post)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    
    func uploadOriginalImage(imageData: Data) async throws -> String {
        let path = "originals/\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child(path)
        _ = try await storageRef.putDataAsync(imageData, metadata: nil)
        return path
    }
    
    func deletePost(postId: String) async throws {
        let snapshot = try await db.collection("posts").document(postId).getDocument()
        guard let data = snapshot.data() else { return }
        
        var pathsToDelete = Set<String>()
        
        if let imageUrl = data["imageUrl"] as? String,
           let path = storagePath(from: imageUrl) {
            pathsToDelete.insert(path)
        }
        
        if let thumbnailUrl = data["thumbnailUrl"] as? String,
           let path = storagePath(from: thumbnailUrl) {
            pathsToDelete.insert(path)
        }
        
        if let originalImagePath = data["originalImagePath"] as? String,
           !originalImagePath.isEmpty {
            pathsToDelete.insert(originalImagePath)
        }
        
        for path in pathsToDelete {
            try await deleteStorageObject(at: path)
        }
        
        try await db.collection("posts").document(postId).delete()
    }
    
    func deletePosts(for userId: String) async throws {
        let snapshot = try await db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for document in snapshot.documents {
            try await deletePost(postId: document.documentID)
        }
    }
    
    private func deleteStorageObject(at path: String) async throws {
        let storageRef = storage.reference().child(path)
        
        do {
            try await storageRef.delete()
        } catch let error as NSError {
            if error.domain == StorageErrorDomain,
               error.code == StorageErrorCode.objectNotFound.rawValue {
                return
            }
            throw error
        }
    }
    
    private func storagePath(from urlString: String) -> String? {
        if urlString.hasPrefix("gs://") {
            let trimmed = String(urlString.dropFirst("gs://".count))
            guard let slashIndex = trimmed.firstIndex(of: "/") else { return nil }
            return String(trimmed[trimmed.index(after: slashIndex)...])
        }
        
        guard
            let components = URLComponents(string: urlString),
            let range = components.percentEncodedPath.range(of: "/o/")
        else {
            return nil
        }
        
        let encodedPath = String(components.percentEncodedPath[range.upperBound...])
        return encodedPath.removingPercentEncoding
    }
}
