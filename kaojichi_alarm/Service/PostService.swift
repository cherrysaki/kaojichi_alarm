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
}

class PostService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func uploadPost(imageData: Data, comment: String?, status:UserStatus, completion: @escaping (Error?) -> Void) async throws -> String {
        
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "PostService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ユーザー未サインイン"])
            completion(error)
            throw error
        }
        
        let postRef = db.collection("posts").document()
        let storageRef = storage.reference().child("posts/\(postRef.documentID).jpg")

        // Compress image before upload
        guard let image = UIImage(data: imageData),
              let compressedData = image.jpegData(compressionQuality: 0.3) else {
            let error = NSError(domain: "PostService", code: -2, userInfo: [NSLocalizedDescriptionKey: "画像圧縮失敗"])
            completion(error)
            throw error
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public,max-age=3600"

        _ = try await storageRef.putDataAsync(compressedData, metadata: metadata)
        let url = try await storageRef.downloadURL()

        // Resize Images対応：サムネイルURLを取得、存在しなければフル画像を使用
        let thumbRef = storage.reference().child("thumbnails/\(postRef.documentID)_400x400.jpg")
        let thumbURL = try? await thumbRef.downloadURL()

        let post: [String: Any] = [
            "id": postRef.documentID,
            "userId": currentUser.uid,
            "postTime": FieldValue.serverTimestamp(),
            "imageUrl": url.absoluteString,
            "thumbnailUrl": thumbURL?.absoluteString ?? url.absoluteString,
            "goodCount": 0,
            "comments": [comment ?? ""],
            "status": status.rawValue
        ]

        let userRef = db.collection("users").document(currentUser.uid)
        let latestStatus: [String: Any] = [
            "latestStatus": status.rawValue,
            "latestStatusUpdatedAt": FieldValue.serverTimestamp()
        ]

        do {
            let batch = db.batch()
            batch.setData(post, forDocument: postRef)
            batch.setData(latestStatus, forDocument: userRef, merge: true)
            try await batch.commit()
            completion(nil)
            return postRef.documentID
        } catch {
            completion(error)
            throw error
        }
    }

    func deletePost(postId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            postRef.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        await deleteStorageObjectIfExists(at: "posts/\(postId).jpg")
        await deleteStorageObjectIfExists(at: "thumbnails/\(postId)_400x400.jpg")
    }

    private func deleteStorageObjectIfExists(at path: String) async {
        let storageRef = storage.reference().child(path)

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                storageRef.delete { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        } catch {
            print("⚠️ ストレージ削除に失敗しました: \(path), \(error.localizedDescription)")
        }
    }
}
