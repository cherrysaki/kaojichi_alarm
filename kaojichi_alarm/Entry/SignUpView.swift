//
//  SignUpView.swift
//  picture_alarm_app
//
//  Created by Keiju Hiramoto on 2025/09/14.
// バグメモ→Authだけ保存してFireStoreに保存されないことがある。2025/09/14/16:32

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseAuthEasier

struct SignUpView: View {
    // メールアドレス/パスワード新規登録廃止のためコメントアウト
//    @StateObject private var viewModel = SignUpViewModel()
    @StateObject private var socialAuthViewModel: FirebaseAuthViewModel
    @State private var socialAuthError = ""

    // サインアップ成功時に親ビューに通知するためのクロージャ
    var onSuccess: (() -> Void)? = nil

    init(onSuccess: (() -> Void)? = nil) {
        self.onSuccess = onSuccess
        let vm = FirebaseAuthViewModel(
            providers: [.apple, .google],
            didSignIn: { result in
                switch result {
                case .success(let authDataResult):
                    let user = authDataResult.user
                    // Firestoreにユーザー情報を保存
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
                            print("ソーシャルサインアップ後のユーザー保存エラー: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    print("ソーシャルサインアップエラー: \(error.localizedDescription)")
                }
            }
        )
        _socialAuthViewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ZStack{
            Color.black
                .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // メールアドレス/パスワード新規登録UI廃止のためコメントアウト
//                        Text("ユーザー情報")
//                            .foregroundStyle(.white)
//                            .font(.headline)
//
//                        TextField("ユーザー名", text: $viewModel.displayName)
//                            .padding(12)
//                            .background(Color.white.opacity(0.1))
//                            .cornerRadius(10)
//                            .foregroundColor(.white)
//                            .textInputAutocapitalization(.never)
//
//                        TextField("メールアドレス", text: $viewModel.email)
//                            .padding(12)
//                            .background(Color.white.opacity(0.1))
//                            .cornerRadius(10)
//                            .foregroundColor(.white)
//                            .textInputAutocapitalization(.never)
//
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("パスワード")
//                                .foregroundStyle(.white)
//                                .font(.headline)
//
//                            SecureField("パスワード(6文字以上)", text: $viewModel.password)
//                                .padding(12)
//                                .background(Color.white.opacity(0.1))
//                                .cornerRadius(10)
//                                .foregroundColor(.white)
//                                .textInputAutocapitalization(.never)
//
//                            SecureField("パスワードの確認", text: $passwordConfirm)
//                                .padding(12)
//                                .background(Color.white.opacity(0.1))
//                                .cornerRadius(10)
//                                .foregroundColor(.white)
//                                .textInputAutocapitalization(.never)
//                        }
                        
                        Spacer()
                        

                        VStack(spacing: 12) {
                            Text("別の方法でログイン")
                                .foregroundStyle(.white)

                            if socialAuthViewModel.isSigningIn {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack(spacing: 24) {
                                    SignInButton(
                                        provider: .apple,
                                        buttonStyle: .black,
                                        labelStyle: .iconOnly,
                                        labelType: .signUp,
                                        cornerStyle: .radius(20),
                                        hasBorder: true
                                    ) {
                                        socialAuthViewModel.handleSignIn(provider: .apple)
                                    }
                                    .frame(width: 60, height: 60)

                                    SignInButton(
                                        provider: .google,
                                        buttonStyle: .black,
                                        labelStyle: .iconOnly,
                                        labelType: .signUp,
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

                        // メールアドレス/パスワード新規登録導線廃止のためコメントアウト
//                        Button("作成") {
//                            Task {
//                                if viewModel.password != passwordConfirm {
//                                    viewModel.message = "パスワードが一致しません"
//                                    return
//                                }
//                                await viewModel.register()
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.orange)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//
//                        if !viewModel.message.isEmpty {
//                            Text(viewModel.message)
//                                .foregroundColor(.red)
//                                .bold()
//                        }

                        if !socialAuthError.isEmpty {
                            Text(socialAuthError)
                                .foregroundColor(.red)
                                .bold()
                        }
                    }
                    .padding(.top, 24)
                }
                .padding(.horizontal, 16)
                .background(Color.black.ignoresSafeArea())
                .navigationTitle("アカウント作成")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("アカウント作成")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .tint(.white)

            // メールアドレス/パスワード新規登録廃止のためコメントアウト
//            .onChange(of: viewModel.isSignUpSuccessful){ _, success in
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
    SignUpView()
}
