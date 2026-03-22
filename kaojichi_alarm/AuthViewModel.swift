import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    
    // 変更をViewに通知するための@Publishedプロパティ
    // ログインしていればFirebaseのUserオブジェクトが、していなければnilが入る
    @Published var user: FirebaseAuth.User?
    @Published var isBootstrappingUser = true
    @Published var bootstrapErrorMessage: String?

    // Firebaseの認証状態監視リスナーへの参照を保持するためのハンドル
    private var handle: AuthStateDidChangeListenerHandle?
    private let userService = UserService.shared

    init() {
        // AuthViewModelが初期化されたときに、Firebaseの認証状態の監視を開始
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                await self?.handleAuthStateChange(user)
            }
        }
    }

    private func handleAuthStateChange(_ user: FirebaseAuth.User?) async {
        self.user = user
        bootstrapErrorMessage = nil

        guard let user else {
            isBootstrappingUser = false
            return
        }

        isBootstrappingUser = true

        do {
            try await userService.ensureUserExists(authData: user)
        } catch {
            bootstrapErrorMessage = "アカウント情報の初期化に失敗しました: \(error.localizedDescription)"
        }

        isBootstrappingUser = false
    }

    func retryBootstrap() {
        guard let user else { return }
        Task { @MainActor in
            await handleAuthStateChange(user)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            bootstrapErrorMessage = "ログアウトに失敗しました: \(error.localizedDescription)"
        }
    }

    deinit {
        // AuthViewModelが破棄されるときに、リスナーを解除してメモリリークを防ぐ
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
