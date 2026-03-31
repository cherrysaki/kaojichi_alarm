//
//  ContentView.swift
//  picture_alarm_app
//
//  Created by tanaka niko on 2025/09/12.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct ContentView: View {
    
    @StateObject var alarmService = AlarmService.shared
    
    @State var isShowAlermStartView: Bool = false
    @State var isShowPopover: Bool = true
    
    @State var wakeuptime = ""
    @State var leaveTime = ""
    
    var body: some View {
        
        ZStack{
            TabView {
                
                TLView()
                    .tabItem {
                        
                        Image(systemName: "house")
                        Text("タイムライン")
                        
                    }
                AlermView()
                    .tabItem {
                        Image(systemName: "deskclock")
                        Text("アラーム")
                    }
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                        Text("プロフィール")
                    }
                
            }
            .tint(Color(hex: "FF8300"))
            .navigationBarBackButtonHidden(true)
            VStack{
                Spacer()
                Button{
                    isShowAlermStartView = true
                }label:{
                    Image(systemName: "camera")
                        .resizable()
                        .foregroundStyle(.white)
                        .scaledToFit()
                        .scaleEffect(0.5)
                        .frame(width: 50, height: 50)
                        .background(.orange)
                        .clipShape(Circle())
                    
                    
                }
                .padding(.bottom, 75) // 下から30ポイント上に配置
                
            }
            
        }
        .fullScreenCover(isPresented: $isShowAlermStartView){
            AlarmStartView()
        }
        .onChange(of: alarmService.shouldReturnToTimeline) { _, newValue in
            if newValue {
                isShowAlermStartView = false
                alarmService.shouldReturnToTimeline = false
            }
        }
        .alert("投稿完了", isPresented: $alarmService.showPostCompletePopup) {
            Button("OK") {}
        } message: {
            Text("投稿が完了しました！")
        }
        .onAppear{
        }
        
        
    }
    
    var popoverView: some View {
        
        
        
        VStack{
        }.onAppear{
            settime()
        }
        .padding()
        
        
    }
    
    private func settime() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH時mm分"
        
        if let current = alarmService.currentAlarm {
            wakeuptime = dateFormatter.string(from: current.wakeUpTime)
            leaveTime  = dateFormatter.string(from: current.leaveTime)
        } else {
            wakeuptime = "--:--"
            leaveTime  = "--:--"
        }
    }
    
    
}

#Preview {
    ContentView()
    
}
