//
//  SignUpViewModel.swift
//  picture_alarm_app
//
//  Created by Keiju Hiramoto on 2025/09/14.
//

import Foundation
import FirebaseAuth
import Combine

// メールアドレス/パスワード新規登録廃止のためコメントアウト
//@MainActor
//class SignUpViewModel: ObservableObject {
//    @Published var displayName = ""
//    @Published var email = ""
//    @Published var password = ""
//    @Published var message = ""
//    @Published var isLoading = false
//    @Published var isSignUpSuccessful = false
//
//    func register() async {
//        isLoading = true
//        message = ""
//        defer { isLoading = false }
//
//        do {
//            let authUser = try await AuthService.shared.createUser(withEmail: email, password: password)
//            try await UserService.shared.saveUser(authData: authUser, name: self.displayName)
//            self.isSignUpSuccessful = true
//
//        } catch {
//            self.message = "アカウント作成に失敗: \(error.localizedDescription)"
//        }
//    }
//}
