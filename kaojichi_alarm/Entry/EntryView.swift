//
//  EntryView.swift
//  picture_alarm_app
//
//  Created by Keiju Hiramoto on 2025/09/14.
//

import SwiftUI
import FirebaseAuth


struct EntryView: View {
    @State private var navigateToLogin = false
    @State private var navigateToSignUp = false
    @State private var navigateToContent = false
    
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
                Text("ログインまたはアカウント作成")
                    .foregroundStyle(.white)
                    .font(.system(size: 18))
                    .padding(.bottom, 10)
                
                VStack(spacing: 20) {
                    // ログイン
                    NavigationLink(destination: LoginView(onSuccess: {
                        self.navigateToContent = true
                    }), isActive: $navigateToLogin) {
                        Text("ログイン")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "FF8300"))
                            .cornerRadius(12)
                    }
                    
                    // サインアップ
                    NavigationLink(destination: SignUpView(onSuccess: {
                        self.navigateToContent = true
                    }), isActive: $navigateToSignUp) {
                        Text("アカウント作成")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
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

                }
                .foregroundStyle(.white)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
                
                // 成功したら ContentView へ
                NavigationLink(destination: ContentView(),
                               isActive: $navigateToContent,
                               label: { EmptyView() })
            }
            .background(.black)
            .ignoresSafeArea()
        }
    }
    
    
}

#Preview {
    EntryView()
}
//developに統合するために無駄に書いたよ！
