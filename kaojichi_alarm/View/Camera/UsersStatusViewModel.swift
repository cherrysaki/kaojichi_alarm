//
//  UsersStatusViewModel.swift
//  picture_alarm_app
//
//  Created by tanaka niko on 2025/09/19.
//

import Foundation
import Combine

//
//  PostListViewModel.swift
//  picture_alarm_app
//
//  Created by A S on 2025/09/15.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class UserStatusViewModel: ObservableObject {
    @Published var userstatus: [String:RappUserStatusInfo] = [:]
    @Published var noActionsUsers:[RappUserStatusInfo] = []
    @Published var isWakeupUsers:[RappUserStatusInfo] = []
    @Published var isLeaveUsers:[RappUserStatusInfo] = []
    
    private let db = Firestore.firestore()
    private let userService = UserService.shared
    private var userCache: [String: User] = [:]
    
    init() {
//        fetchUsersStatus()
    }
    
    /// 各友達の「今日の最新投稿」を1件ずつ取得する関数
    func fetchUsersStatus() {
        
        userstatus.removeAll()
        noActionsUsers.removeAll()
        isWakeupUsers.removeAll()
        isLeaveUsers.removeAll()
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        Task {
            do {
                // 友達のIDリストを取得
                let friendIds = Array(Set(try await userService.fetchFriendIds(forUserId: currentUserId) + [currentUserId]))
                
                
                
                // friendIdsが空の場合はFirestoreにクエリを投げずに空の配列を返す
                if friendIds.isEmpty {
                    //                    completion([])
                    return
                }
                
                // 1. 「今日」の開始時刻と「明日」の開始時刻を計算する
                let calendar = Calendar.current
                let now = Date()
                let startOfToday = calendar.startOfDay(for: now)
                guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
                    //                    completion([])
                    return
                }
                
                let friendIdsSet = Set(friendIds)
                
                let snapshot = try await db.collection("posts")
                    .whereField("postTime", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
                    .whereField("postTime", isLessThan: Timestamp(date: startOfTomorrow))
                    .getDocuments()
                
                var latestStatus: [String: RappUserStatusInfo] = [:]
                var usersWithPostToday = Set<String>()
                let missingUserIds = friendIds.filter { userCache[$0] == nil }

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

                for userId in friendIds {
                    latestStatus[userId] = RappUserStatusInfo(
                        id: userId,
                        user: userCache[userId],
                        status: .noActions
                    )
                }

                let sortedDocuments = snapshot.documents.sorted {
                    let lhs = ($0.data()["postTime"] as? Timestamp)?.dateValue() ?? .distantPast
                    let rhs = ($1.data()["postTime"] as? Timestamp)?.dateValue() ?? .distantPast
                    return lhs > rhs
                }

                for doc in sortedDocuments {
                    // 3. アプリ側でフィルタリングし、各ユーザーの「今日の最新投稿」を1件だけ取り出す
                   
                    
                    // ドキュメントをループ処理
         
                        let data = doc.data()
                        
                        // postTimeをDateに変換
                        guard let timestamp = data["postTime"] as? Timestamp else { continue }
                        
                        let postDate = timestamp.dateValue()
                        
                        // 今日の投稿であり、まだそのユーザーの投稿を結果に追加していない場合のみ処理
                        if postDate >= startOfToday && postDate < startOfTomorrow {
                      
                            guard let userId = data["userId"] as? String else { continue }
                            guard friendIdsSet.contains(userId) else { continue }
                            guard !usersWithPostToday.contains(userId) else { continue }
                            let rawStatus = data["status"] as? String ?? ""
                            let status = UserStatus(rawValue: rawStatus) ?? .noActions
                            
                            latestStatus[userId]?.status = status
                            usersWithPostToday.insert(userId)
                        }
                    
                   
                }
                
                await MainActor.run {
                    self.userstatus.removeAll()
                    self.noActionsUsers.removeAll()
                    self.isWakeupUsers.removeAll()
                    self.isLeaveUsers.removeAll()
                    
                    self.userstatus = latestStatus
                    
                  for info in userstatus.values {
                    switch info.status {
                    case .noActions:
                        self.noActionsUsers.append(info)
                    case .isWakeup:
                        self.isWakeupUsers.append(info)
                    case .isLeave:
                        self.isLeaveUsers.append(info)
                    case .none:
                        self.noActionsUsers.append(info)
                        break // 何もしない
                    }
                }
                
                }
            } catch {
                print("Error fetching friends: \(error.localizedDescription)")
            }
        }
    }
    
    
    
}
enum UserStatus: String, Codable {
    case noActions = "noaction"
    case isWakeup = "iswakeup"
    case isLeave = "isleave"
}

struct UserStatusInfo: Identifiable {
    var id: String //ユーザのID
    var user: User? //ユーザー情報
    var status:String? //ユーザーの起床状況
}

struct RappUserStatusInfo: Identifiable {
    var id: String //ユーザのID
    var user: User? //ユーザー情報
    var status:UserStatus? //ユーザーの起床状況
}
