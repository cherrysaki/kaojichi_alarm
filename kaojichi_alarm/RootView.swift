import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @AppStorage("hasCompletedPermissionFlow") private var hasCompletedPermissionFlow = false

    var body: some View {
        if authViewModel.user != nil {
            ContentView()
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
