//
//  AlarmPrepareView.swift
//  picture_alarm_app
//
//  Created by tanaka niko on 2025/09/16.
//

import SwiftUI

struct AlarmPrepareView: View {
    
    @StateObject private var alarmService = AlarmService.shared
    
    @State var wakeupTimeText = ""
    @State var leaveTimeText = ""
    @State var isAlarmStart = false
    @State private var isShowAlarmSettingView = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                if let currentAlarm = alarmService.currentAlarm {
                    if currentAlarm.isWakeup && !currentAlarm.isLeave {
                        DepartureCountdownView(
                            departureTime: currentAlarm.leaveTime,
                            wakeUpImage: UIImage(systemName: "house")
                        )
                    } else if !currentAlarm.isWakeup {
                        CameraViewWrapper()
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
            
            if alarmService.getTodayAlarm() == nil {
                alarmService.isAlarmOn = false
            } else {
                alarmService.isAlarmOn = true
                
                if let currentAlarm = alarmService.currentAlarm {
                    alarmService.updateAlarmStatus(
                        id: currentAlarm.id,
                        isOn: true,
                        isWakeup: false,
                        isLeave: false
                    )
                }
            }
            
            UserDefaults.standard.set(alarmService.isAlarmOn, forKey: "isAlarmOn")
            
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            
            if let currentAlarm = alarmService.currentAlarm {
                wakeupTimeText = formatter.string(for: currentAlarm.wakeUpTime) ?? ""
                leaveTimeText = formatter.string(for: currentAlarm.leaveTime) ?? ""
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
    AlarmPrepareView()
}
