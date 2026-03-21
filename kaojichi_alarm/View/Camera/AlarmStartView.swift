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
                    if alarmService.isAlarmOn {
                        if let currentAlarm = alarmService.currentAlarm {
                            if !currentAlarm.isWakeup || !currentAlarm.isLeave {
                                AlarmPrepareView()
                            } else {
                                AlarmDoneView()
                            }
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
                    wakeupTimeText = {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .none
                        formatter.timeStyle = .medium
                        return formatter.string(from: todayAlarm.wakeUpTime)
                    }()
                    leaveTimeText = {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .none
                        formatter.timeStyle = .medium
                        return formatter.string(from: todayAlarm.leaveTime)
                    }()
                } else {
                    alarmService.isAlarmOn = false
                }
                
                UserDefaults.standard.set(alarmService.isAlarmOn, forKey: "isAlarmOn")
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
}

#Preview {
    AlarmStartView()
}
