//
//  EntryView.swift
//  picture_alarm_app
//
//  Created by Keiju Hiramoto on 2025/09/14.
//

import SwiftUI
import FirebaseAuthEasier
import FirebaseAuth


struct EntryView: View {
    @StateObject private var socialAuthViewModel: FirebaseAuthViewModel
    @State private var socialAuthError = ""

    init() {
        let vm = FirebaseAuthViewModel(
            providers: [.apple, .google],
            didSignIn: { result in
                switch result {
                case .success(let authDataResult):
                    let user = authDataResult.user

                    Task {
                        do {
                            let existingUser = try await UserService.shared.fetchUser(withId: user.uid)
                            if existingUser == nil {
                                try await UserService.shared.saveUser(
                                    authData: user,
                                    name: user.displayName ?? "ユーザー"
                                )
                            }
                        } catch {
                            print("EntryViewからのソーシャルログイン後のユーザー保存エラー: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    print("EntryViewからのソーシャルログインエラー: \(error.localizedDescription)")
                }
            }
        )
        _socialAuthViewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25){
                Spacer()
                Image("appicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
//                    .padding(.bottom, 0)
                
                Text("顔質アラーム")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)
//                Text("ログインまたはアカウント作成")
                    .foregroundStyle(.white)
                    .font(.system(size: 18))
                    .padding(.bottom, 10)
                
                VStack(spacing: 20) {
                    if socialAuthViewModel.isSigningIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        SignInButton(
                            provider: .apple,
                            buttonStyle: .black,
                            labelStyle: .titleAndIcon,
                            labelType: .continue,
                            cornerStyle: .radius(12),
                            hasBorder: true
                        ) {
                            socialAuthError = ""
                            socialAuthViewModel.handleSignIn(provider: .apple)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 60)

                        SignInButton(
                            provider: .google,
                            buttonStyle: .white,
                            labelStyle: .titleAndIcon,
                            labelType: .continue,
                            cornerStyle: .radius(12),
                            hasBorder: false
                        ) {
                            socialAuthError = ""
                            socialAuthViewModel.handleSignIn(provider: .google)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .padding(.bottom, 15)
                    }
                    
                    //                    Text("続行することで利用規約及びプライバシーポリシーに同意したとみなします")
                    //                        .foregroundStyle(.white)
                    //                        .font(.system(size: 15))
                    //                        .padding(.bottom, 20)
        
                    HStack(spacing: 2) {
                        Text("続行することで")
                            .foregroundColor(.white)
                        
                        Link("利用規約",
                             destination: URL(string: "https://doc-hosting.flycricket.io/yan-zhi-aramu-terms-of-use/608f5913-89c9-496c-a4c7-95c073f39c1d/terms")!)
                        .foregroundColor(.orange)
                
                        Text("及び")
                        
                        Link("プライバシーポリシー",
                             destination: URL(string: "https://doc-hosting.flycricket.io/yan-zhi-aramu-privacy-policy/41755d4b-01aa-49cd-9b34-fdc92e94f437/privacy")!)
                        .foregroundColor(.orange)
                        Text("に同意したとみなします")
                            
                        
                        
                    }
                    .font(.system(size: 11))
                    .multilineTextAlignment(.center)

                    if !socialAuthError.isEmpty {
                        Text(socialAuthError)
                            .foregroundColor(.red)
                            .bold()
                    }

                }
                .foregroundStyle(.white)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
            .background(.black)
            .ignoresSafeArea()
            .onChange(of: socialAuthViewModel.lastSignInResult != nil) { _, hasResult in
                if hasResult,
                   case .failure(let error) = socialAuthViewModel.lastSignInResult {
                    socialAuthError = error.localizedDescription
                }
            }
        }
    }
    
    
}

#Preview {
    EntryView()
}
//developに統合するために無駄に書いたよ！

