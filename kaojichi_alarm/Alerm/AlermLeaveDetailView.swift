//
//  AlermLeaveDetailView.swift
//  picture_alarm_app
//
//  Created by 酒井みな実 on 2025/09/17.
//

import SwiftUI
import UserNotifications

struct AlermLeaveDetailView: View {
    @Binding var wakeUpTime: Date
    @Binding var leaveTime: Date
    @Binding var isShowLeaveDetailView: Bool
    @Binding var alarmStatus: alarmStatus
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            Text("出発時間を設定")
                .font(.headline)
                .foregroundColor(.white)
            
            DatePicker(
                "",
                selection: $leaveTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(.themeOrange)
            .environment(\.colorScheme, .dark)
            .frame(height: 200)
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            HStack(spacing: 16) {
                Button {
                    saveAlarm()
                } label: {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.themeOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.visible)
        .onAppear {
            requestNotificationAuthorization()
        }
    }
    
    private func saveAlarm() {
        print(selectedDate)
        
        let combinedDate = calendar.date(
            bySettingHour: calendar.component(.hour, from: wakeUpTime),
            minute: calendar.component(.minute, from: wakeUpTime),
            second: 0,
            of: selectedDate
        ) ?? selectedDate
        
        let combinedLeaveTime = calendar.date(
            bySettingHour: calendar.component(.hour, from: leaveTime),
            minute: calendar.component(.minute, from: leaveTime),
            second: 0,
            of: selectedDate
        ) ?? selectedDate
        
        print("DEBUG: if文の直前のselectedDateの値 -> \(selectedDate)")
        
        if combinedDate <= combinedLeaveTime {
            if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
                if let alarms = AlarmService.shared.getAlarm(for: selectedDate) {
                    AlarmService.shared.updateAlarm(
                        id: alarms.id,
                        date: selectedDate,
                        wakeUpTime: combinedDate,
                        leaveTime: combinedLeaveTime,
                        isOn: true
                    )
                } else {
                    AlarmService.shared.addAlarm(
                        date: selectedDate,
                        wakeUpTime: combinedDate,
                        leaveTime: combinedLeaveTime,
                        isOn: true
                    )
                }
                
                let background = BackgroundTasks()
                background.scheduleDepaturePostSetup()
                
                print("a")
            } else {
                if let alarms = AlarmService.shared.getAlarm(for: selectedDate) {
                    AlarmService.shared.updateAlarm(
                        id: alarms.id,
                        date: selectedDate,
                        wakeUpTime: combinedDate,
                        leaveTime: combinedLeaveTime,
                        isOn: false
                    )
                } else {
                    AlarmService.shared.addAlarm(
                        date: selectedDate,
                        wakeUpTime: combinedDate,
                        leaveTime: combinedLeaveTime,
                        isOn: false
                    )
                }
                
                print("b")
            }
            
            alarmStatus = .setted
            
            print(AlarmService.shared.getAlarm(for: selectedDate)?.date as Any)
            print(AlarmService.shared.getAlarm(for: selectedDate)?.wakeUpTime as Any)
            print(AlarmService.shared.getAlarm(for: selectedDate)?.leaveTime as Any)
        } else {
            alarmStatus = .error
        }
        
        print(AlarmService.shared.getAlarm(for: selectedDate) as Any)
        
        dismiss()
    }
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }
}

