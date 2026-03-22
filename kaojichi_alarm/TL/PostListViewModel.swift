//
//  PostListViewModel.swift
//  picture_alarm_app
//
//  Created by A S on 2025/09/15.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

class PostListViewModel: ObservableObject {
    @Published var posts: [PostInfo] = []
    
    private let db = Firestore.firestore()
    private let userService = UserService.shared
    private var postsListener: ListenerRegistration?
    private var userCache: [String: User] = [:]
    
    init() {
        fetchPosts()
    }

    deinit {
        postsListener?.remove()
    }
    
    func fetchPosts() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                // 自分と友達のIDを取得
                let friendIds = Array(Set(try await userService.fetchFriendIds(forUserId: currentUserId) + [currentUserId]))

                postsListener?.remove()

                // Firestoreからpostsを取得
                postsListener = db.collection("posts")
                    .whereField("userId", in: friendIds)
                    .order(by: "postTime", descending: true)
                    .limit(to: 100)
                    .addSnapshotListener { [weak self] snapshot, error in
                        guard let self = self, let documents = snapshot?.documents else { return }

                        Task {
                            let calendar = Calendar.current
                            let startOfToday = calendar.startOfDay(for: Date())
                            guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
                                return
                            }

                            let todayDocuments = documents.filter { doc in
                                guard let timestamp = doc.data()["postTime"] as? Timestamp else {
                                    return false
                                }

                                let postDate = timestamp.dateValue()
                                return postDate >= startOfToday && postDate < startOfTomorrow
                            }

                            let missingUserIds = Set(
                                todayDocuments.compactMap { $0.data()["userId"] as? String }
                            ).subtracting(Set(self.userCache.keys))

                            if !missingUserIds.isEmpty {
                                await withTaskGroup(of: (String, User?).self) { group in
                                    for userId in missingUserIds {
                                        group.addTask {
                                            let user = try? await self.userService.fetchUser(withId: userId)
                                            return (userId, user)
                                        }
                                    }

                                    for await (userId, user) in group {
                                        if let user {
                                            self.userCache[userId] = user
                                        }
                                    }
                                }
                            }

                            let newPosts = todayDocuments.compactMap { doc -> PostInfo? in
                                let data = doc.data()
                                let userId = data["userId"] as? String ?? ""

                                return PostInfo(
                                    id: doc.documentID,
                                    userId: userId,
                                    postTime: (data["postTime"] as? Timestamp)?.dateValue(),
                                    imageUrl: data["imageUrl"] as? String,
                                    goodCount: data["goodCount"] as? Int ?? 0,
                                    comments: data["comments"] as? [String] ?? [],
                                    user: self.userCache[userId],
                                    status: data["status"] as? String,
                                    thumbnailUrl: data["thumbnailUrl"] as? String
                                )
                            }

                            await MainActor.run {
                                self.posts = newPosts
                            }
                        }
                    }
            } catch {
                print("Error fetching friends: \(error.localizedDescription)")
            }
        }
    }
}
