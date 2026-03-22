import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @AppStorage("hasCompletedPermissionFlow") private var hasCompletedPermissionFlow = false

    var body: some View {
        if authViewModel.user != nil {
            if authViewModel.isBootstrappingUser {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView("アカウント情報を準備しています")
                        .tint(.white)
                        .foregroundStyle(.white)
                }
            } else if let bootstrapErrorMessage = authViewModel.bootstrapErrorMessage {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("アカウント情報を読み込めませんでした")
                            .foregroundStyle(.white)
                            .font(.headline)
                        Text(bootstrapErrorMessage)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                        Button("再試行") {
                            authViewModel.retryBootstrap()
                        }
                        Button("ログアウト") {
                            authViewModel.signOut()
                        }
                    }
                    .padding(24)
                }
            } else {
                ContentView()
            }
        } else {
            if !hasSeenTutorial {
                TutorialView()
            } else if !hasCompletedPermissionFlow {
                PermissionIntroView()
            } else {
                EntryView()
            }
        }
    }
}
