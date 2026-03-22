import Foundation
import Combine
import FirebaseAuth

@MainActor
class AddFriendViewModel: ObservableObject {
    
    enum RelationshipStatus {
        case none, requestSent, requestReceived, friends
    }
    
    @Published var searchText = ""
    @Published var searchResults: [User] = []
    @Published var relationshipStatus: [String: RelationshipStatus] = [:]
    @Published var isLoading = false
    
    private var sentRequests: [String: FriendRequest] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let currentUserId = Auth.auth().currentUser?.uid
    private let userService = UserService.shared

    init() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task { await self?.performSearch(query: query) }
            }
            .store(in: &cancellables)
    }
    
    func performSearch(query: String) async {
        guard let currentUserId = self.currentUserId, !query.isEmpty else {
            self.searchResults = []
            self.relationshipStatus = [:]
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let users = try await userService.searchUsers(byName: query)
            self.searchResults = users

            if users.isEmpty {
                self.relationshipStatus = [:]
                self.sentRequests = [:]
                return
            }

            async let friendIdsTask = userService.fetchFriendIds(forUserId: currentUserId)
            async let sentRequestsTask = userService.fetchSentFriendRequests(for: currentUserId)
            async let incomingRequestsTask = userService.fetchIncomingFriendRequests(for: currentUserId)

            let friendIds = try await friendIdsTask
            let sentRequests = try await sentRequestsTask
            let incomingRequests = try await incomingRequestsTask

            let friendsSet = Set(friendIds)
            let sentRequestsByUser = Dictionary(uniqueKeysWithValues: sentRequests.map { ($0.toId, $0) })
            let incomingRequestsByUser = Dictionary(uniqueKeysWithValues: incomingRequests.map { ($0.fromId, $0) })

            self.sentRequests = sentRequestsByUser
            self.relationshipStatus = Dictionary(uniqueKeysWithValues: users.map { user in
                let status: RelationshipStatus

                if friendsSet.contains(user.id) {
                    status = .friends
                } else if sentRequestsByUser[user.id] != nil {
                    status = .requestSent
                } else if incomingRequestsByUser[user.id] != nil {
                    status = .requestReceived
                } else {
                    status = .none
                }

                return (user.id, status)
            })
        } catch {
            print("Error searching users: \(error.localizedDescription)")
            self.searchResults = []
            self.relationshipStatus = [:]
        }
    }
    
    func sendFriendRequest(to user: User) async {
        guard let currentUserId = self.currentUserId else { return }
        let userId = user.id // 👇 guard letは不要
        
        relationshipStatus[userId] = .requestSent
        
        do {
            try await userService.sendFriendRequest(to: userId, from: currentUserId)
            await performSearch(query: self.searchText)
        } catch {
            print("Error sending friend request: \(error.localizedDescription)")
            relationshipStatus[userId] = RelationshipStatus.none
        }
    }
    
    func cancelFriendRequest(to user: User) async {
        let userId = user.id // 👇 guard letは不要
        guard let requestToCancel = self.sentRequests[userId] else { return }
        
        relationshipStatus[userId] = RelationshipStatus.none
        
        do {
            try await userService.declineFriendRequest(requestId: requestToCancel.id)
        } catch {
            print("Error canceling friend request: \(error.localizedDescription)")
            relationshipStatus[userId] = .requestSent
        }
    }
}
