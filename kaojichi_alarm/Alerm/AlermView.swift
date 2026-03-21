//
//  AlermView.swift
//  picture_alarm_app
//
//  Created by A S on 2025/09/12.
//

import SwiftUI
import UserNotifications
import SwiftData

struct AlermView: View {
    
    @State private var alarms: [AlarmData] = []
    @StateObject private var alarmService = AlarmService.shared
    
    @State private var wakeUpTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    
    @State private var leaveTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    
    @State private var showingAlarmDetail = false
    @State private var selectedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var editedAlarm: AlarmData?
    
    // 初期状態は必ずOFF
    @State private var isAlarmOn: Bool = false
    
    // 起床時間/出発時間のモーダル表示フラグ
    @State private var isShowWakuUpDetailView = false
    @State private var isShowLeaveDetailView = false
    
    // 表示状態は毎回ここから計算
    private var currentAlarmStatus: alarmStatus {
        if !isAlarmOn {
            return .unsetted
        } else if wakeUpTime >= leaveTime {
            return .error
        } else {
            return .setted
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                
                // --- 年 + 今日ボタン ---
                HStack {
                    Text(yearString)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
                    }) {
                        Text("今日")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Calendar.current.isDate(selectedDate, inSameDayAs: Date())
                                ? Color.gray.opacity(0.5)
                                : Color.themeOrange
                            )
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // --- 月/日セレクタ ---
                MonthSelector(selectedDate: $selectedDate)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                
                DaySelector(selectedDate: $selectedDate)
                
                Divider()
                    .background(.white)
                    .padding(.top, 10)
                
                // --- toggle ---
                Toggle("アラーム", isOn: $isAlarmOn)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding()
                    .onChange(of: isAlarmOn) { _, newValue in
                        let normalizedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                        selectedDate = normalizedDate
                        
                        if let alarm = alarmService.getAlarm(for: normalizedDate) {
                            alarmService.updateAlarm(
                                id: alarm.id,
                                date: normalizedDate,
                                wakeUpTime: wakeUpTime,
                                leaveTime: leaveTime,
                                isOn: newValue
                            )
                        } else {
                            // まだその日のアラームがなければ新規作成
                            alarmService.addAlarm(
                                date: normalizedDate,
                                wakeUpTime: wakeUpTime,
                                leaveTime: leaveTime,
                                isOn: newValue
                            )
                        }
                    }
                
                Divider()
                    .background(.white)
                
                // --- 状態表示文章 ---
                switch currentAlarmStatus {
                case .setted:
                    HStack(alignment: .center) {
                        Spacer()
                        Image(systemName: "clock.badge.checkmark.fill")
                        Text(" アラームは設定されています")
                        Spacer()
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.themeOrange.opacity(0.2))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top)
                    
                case .unsetted:
                    HStack(alignment: .center) {
                        Spacer()
                        Image(systemName: "clock.badge.xmark.fill")
                        Text(" アラームは設定されていません")
                        Spacer()
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.themeOrange.opacity(0.2))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top)
                    
                case .error:
                    HStack(alignment: .center) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .symbolRenderingMode(.multicolor)
                        Text("出発時刻よりも起床時刻が早くなっています！アラームは作動しません！")
                        Spacer()
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.themeOrange.opacity(0.2))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top)
                }
                
                // --- 時刻カード ---
                VStack(spacing: 28) {
                    TimeCardView(title: "起床時刻", time: wakeUpTime)
                        .onTapGesture {
                            isShowWakuUpDetailView = true
                        }
                    
                    TimeCardView(title: "出発時刻", time: leaveTime)
                        .onTapGesture {
                            isShowLeaveDetailView = true
                        }
                }
                .padding(.horizontal, 16)
                .padding(.top, 28)
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("")
            
            // --- 詳細編集シート ---
            .sheet(isPresented: $showingAlarmDetail) {
                AlermDetailView(wakeUpTime: $wakeUpTime, leaveTime: $leaveTime)
            }
            
            // --- 起床時間モーダル ---
            .sheet(isPresented: $isShowWakuUpDetailView) {
                AlermWakuUpDetailView(
                    wakeUpTime: $wakeUpTime,
                    leaveTime: $leaveTime,
                    isShowWakuUpDetailView: $isShowWakuUpDetailView,
                    alarmStatus: .constant(currentAlarmStatus),
                    selectedDate: $selectedDate
                )
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
            }
            
            // --- 出発時間モーダル ---
            .sheet(isPresented: $isShowLeaveDetailView) {
                AlermLeaveDetailView(
                    wakeUpTime: $wakeUpTime,
                    leaveTime: $leaveTime,
                    isShowLeaveDetailView: $isShowLeaveDetailView,
                    alarmStatus: .constant(currentAlarmStatus),
                    selectedDate: $selectedDate
                )
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
            }
            
            // --- 初回表示時 ---
            .onAppear {
                loadAlarmForSelectedDate()
            }
            
            // --- 日付変更時 ---
            .onChange(of: selectedDate) {
                loadAlarmForSelectedDate()
            }
        }
    }
    
    // MARK: - 日付ごとのアラーム読込
    private func loadAlarmForSelectedDate() {
        let normalizedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        selectedDate = normalizedDate
        
        // まず必ずOFFから始める
        isAlarmOn = false
        editedAlarm = nil
        
        alarmService.fetchAlarms()
        alarms = alarmService.alarms
        
        if let alarm = alarmService.getAlarm(for: normalizedDate) {
            editedAlarm = alarm
            wakeUpTime = alarm.wakeUpTime
            leaveTime = alarm.leaveTime
            isAlarmOn = alarm.isOn
        } else {
            wakeUpTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
            leaveTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
            isAlarmOn = false
        }
    }
    
    // MARK: - 日付表示ユーティリティ
    private var yearString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年"
        return f.string(from: selectedDate)
    }
}

#Preview {
    AlermView()
}

