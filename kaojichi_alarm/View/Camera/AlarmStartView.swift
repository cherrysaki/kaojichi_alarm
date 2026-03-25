//
//  AlarmStartView.swift
//  picture_alarm_app
//
//  Created by tanaka niko on 2025/09/16.
//

import SwiftUI

struct AlarmStartView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var alarmService = AlarmService.shared
    
    @State var wakeupTimeText = ""
    @State var leaveTimeText = ""
    @State var isAlarmStart = false
    @State private var isShowAlarmSettingView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    if let currentAlarm = alarmService.currentAlarm {
                        if currentAlarm.isWakeup && currentAlarm.isLeave {
                            completedAlarmView
                        } else if currentAlarm.isOn {
                            AlarmPrepareView()
                        } else {
                            noAlarmView
                        }
                    } else {
                        noAlarmView
                    }
                }
            }
            .sheet(isPresented: $isShowAlarmSettingView) {
                AlermView()
            }
            .onAppear {
                alarmService.fetchAlarms()

                if let todayAlarm = alarmService.getTodayAlarm() {
                    alarmService.isAlarmOn = todayAlarm.isOn
                } else {
                    alarmService.isAlarmOn = false
                }
                
                UserDefaults.standard.set(alarmService.isAlarmOn, forKey: "isAlarmOn")
                
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .medium
                
                if let currentAlarm = alarmService.currentAlarm {
                    wakeupTimeText = formatter.string(from: currentAlarm.wakeUpTime)
                    leaveTimeText = formatter.string(from: currentAlarm.leaveTime)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "multiply")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var noAlarmView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "alarm")
                .font(.system(size: 52))
                .foregroundColor(.orange)
            
            Text("アラームが設定されていません")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            
            Text("起床時間と出発時間を設定して、\nアラームを始めましょう")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button {
                isShowAlarmSettingView = true
            } label: {
                Text("アラームを設定する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "FF8300"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var completedAlarmView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundColor(.orange)

            Text("今日のアラームは完了しました")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            Text("起床と出発の投稿が完了しています。")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("タイムラインに戻る")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "FF8300"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    AlarmStartView()
}
