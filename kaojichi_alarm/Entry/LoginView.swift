//
//  LoginView.swift
//  picture_alarm_app
//
//  Created by Keiju Hiramoto on 2025/09/14.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseAuthEasier

struct LoginView: View {
    // メールアドレス/パスワードログイン廃止のためコメントアウト
//    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var socialAuthViewModel: FirebaseAuthViewModel
    @State private var socialAuthError = ""

    var onSuccess: (() -> Void)? = nil

    init(onSuccess: (() -> Void)? = nil) {
        self.onSuccess = onSuccess
        // didSignInコールバックでソーシャルログイン成功時の処理を行う
        let vm = FirebaseAuthViewModel(
            providers: [.apple, .google],
            didSignIn: { result in
                switch result {
                case .success(let authDataResult):
                    let user = authDataResult.user
                    // Firestoreにユーザー情報を保存（初回ログイン時のみ）
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
                            print("ソーシャルログイン後のユーザー保存エラー: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    print("ソーシャルログインエラー: \(error.localizedDescription)")
                }
            }
        )
        _socialAuthViewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // メールアドレス/パスワードログインUI廃止のためコメントアウト
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("メールアドレス")
//                                .foregroundStyle(.white)
//                                .font(.headline)
//
//                            TextField("メールアドレス", text: $viewModel.email)
//                                .padding(12)
//                                .background(Color.white.opacity(0.1))
//                                .cornerRadius(10)
//                                .foregroundColor(.white)
//                                .textInputAutocapitalization(.never)
//                        }
//
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("パスワード")
//                                .foregroundStyle(.white)
//                                .font(.headline)
//
//                            SecureField("パスワード", text: $viewModel.password)
//                                .padding(12)
//                                .background(Color.white.opacity(0.1))
//                                .cornerRadius(10)
//                                .foregroundColor(.white)
//                                .textInputAutocapitalization(.never)
//                        }

                        Spacer()

                        VStack(spacing: 12) {
//                            Text("別の方法でログイン")
//                                .foregroundStyle(.white)

                            if socialAuthViewModel.isSigningIn {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                VStack(spacing: 24) {
                                    SignInButton(
                                        provider: .apple,
                                        buttonStyle: .black,
                                        labelStyle: .titleAndIcon,
                                        labelType: .signIn,
                                        cornerStyle: .radius(20),
                                        hasBorder: true
                                    ) {
                                        socialAuthViewModel.handleSignIn(provider: .apple)
                                    }
                                    .frame(width: 60, height: 60)

                                    SignInButton(
                                        provider: .google,
                                        buttonStyle: .black,
                                        labelStyle: .titleAndIcon,
                                        labelType: .signIn,
                                        cornerStyle: .radius(20),
                                        hasBorder: true
                                    ) {
                                        socialAuthViewModel.handleSignIn(provider: .google)
                                    }
                                    .frame(width: 60, height: 60)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Spacer()
                        Spacer()

                        // メールアドレス/パスワードログイン導線廃止のためコメントアウト
//                        Button(action: viewModel.login) {
//                            if viewModel.isLoading {
//                                HStack {
//                                    ProgressView()
//                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                                    Text("ログイン中")
//                                        .foregroundColor(.white)
//                                }
//                            } else {
//                                Text("ログイン")
//                                    .foregroundColor(.white)
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.orange)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                        .disabled(viewModel.isLoading)
//
//                        if !viewModel.errorMessage.isEmpty {
//                            Text(viewModel.errorMessage)
//                                .foregroundColor(.red)
//                                .bold()
//                        }

                        if !socialAuthError.isEmpty {
                            Text(socialAuthError)
                                .foregroundColor(.red)
                                .bold()
                        }
                    }
                    .padding()
                }
                .padding(.horizontal, 16)
                .background(Color.black.ignoresSafeArea())
                .navigationTitle("ログイン")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("ログイン")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .tint(.white)
            // メールアドレス/パスワードログイン廃止のためコメントアウト
//            .onChange(of: viewModel.isLoginSuccessful) { _, success in
//                if success {
//                    onSuccess?()
//                }
//            }
            .onChange(of: socialAuthViewModel.lastSignInResult != nil) { _, hasResult in
                if hasResult {
                    if case .success = socialAuthViewModel.lastSignInResult {
                        onSuccess?()
                    } else if case .failure(let error) = socialAuthViewModel.lastSignInResult {
                        socialAuthError = error.localizedDescription
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
