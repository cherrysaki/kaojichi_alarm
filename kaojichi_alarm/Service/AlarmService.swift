//
//  AlarmService.swift
//  picture_alarm_app
//
//  Created by Assistant on 2025/09/14.
//

import Foundation
import AVFoundation
import AudioToolbox
import UserNotifications
import SwiftData
import SwiftUI
import Combine

// アラームのビューモデル
@MainActor
class AlarmService: ObservableObject {


    private let context = sharedModelContainer.mainContext
    
    static let shared = AlarmService()
    
    @Published var alarms: [AlarmData] = []
    @Published var currentAlarm: AlarmData?
    private var timer: Timer?
    private var alarmTimer: Timer?
    private let wakeupNotificationInterval: TimeInterval = 5
    private let maxWakeupNotificationCount = 60
    @Published var isAlarmPlaying = false
    @Published var isAlarmOn: Bool = UserDefaults.standard.value(forKey: "isAlarmOn") as? Bool ?? false
    @Published var isWakeup: Bool = false
    @Published var isLeave: Bool = false
    @Published var shouldReturnToTimeline: Bool = false
    @Published var showPostCompletePopup: Bool = false



    private init() {
        setupAudioSession()
        requestNotificationPermission()
        fetchAlarms() // 変更点 2: 初期化時にデータを取得する
        startMonitoring()
        setTodayAlarm()
        
    }
    
    // 変更点 3: 手動でデータを取得するメソッドを追加
    /// SwiftDataからアラームを全て取得し、`alarms`プロパティを更新する
    func fetchAlarms() {
        let descriptor = FetchDescriptor<AlarmData>(sortBy: [SortDescriptor(\.date)])
        do {
            self.alarms = try context.fetch(descriptor)
            print("アラームの取得に成功: \(alarms.count)件")
        } catch {
            print("アラームの取得に失敗: \(error)")
        }
//        print(self.alarms)
    }
    
    /// 日毎のアラームを追加
    func addAlarm(date: Date, wakeUpTime: Date, leaveTime: Date,isOn:Bool) {
        var calendar = Calendar(identifier: .gregorian)
//
//        if let jstTimeZone = TimeZone(identifier: "Asia/Tokyo") {
//            calendar.timeZone = jstTimeZone
//        }
//
        // 変更点 4: `alarmdata`を`alarms`に変更
        if let index = alarms.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }){
            print("a")
            updateAlarm(
                   id: alarms[index].id,
                   date: date, // ✅ 新しい日付を正しく渡す
                   wakeUpTime: wakeUpTime,
                   leaveTime: leaveTime,
                   isOn: isOn
               )
        } else {
            let alarm = AlarmData(date: date, wakeUpTime: wakeUpTime, leaveTime: leaveTime)
            print("b")
            alarm.isOn = isOn
            context.insert(alarm)
            do {
                try context.save()
                let descriptor = FetchDescriptor<AlarmData>(sortBy: [SortDescriptor(\.date)])
                    self.alarms = try context.fetch(descriptor)
                print("✅ アラームの保存に成功しました。")
            } catch {
                print("❌ アラームの保存に失敗しました: \(error)")
            }
            
            saveAndFetchAlarms() // 変更点 5: 保存と再取得を1つのメソッドにまとめる
            startMonitoring()
            scheduleNotification(for: alarm)
        }
    }
    
    /// アラームを更新
    func updateAlarm(id: String, date: Date, wakeUpTime: Date, leaveTime: Date,isOn:Bool) {
        // alarms配列から更新対象のアラーム（への参照）を探す
            if let alarmToUpdate = alarms.first(where: { $0.id == id }) {
                let previousIsOn = alarmToUpdate.isOn
                let shouldResetProgress =
                    isOn && (
                        !previousIsOn ||
                        alarmToUpdate.date != date ||
                        alarmToUpdate.wakeUpTime != wakeUpTime ||
                        alarmToUpdate.leaveTime != leaveTime
                    )
                
                // 参照している元のオブジェクトのプロパティを直接変更する
                alarmToUpdate.date = date
                alarmToUpdate.wakeUpTime = wakeUpTime
                alarmToUpdate.leaveTime = leaveTime
                alarmToUpdate.isOn = isOn //ついか
                if shouldResetProgress {
                    alarmToUpdate.isWakeup = false
                    alarmToUpdate.isLeave = false
                    UserDefaults.standard.removeObject(forKey: "wakeupImage")
                    UserDefaults.standard.removeObject(forKey: "wakeupImageData")
                    UserDefaults.standard.removeObject(forKey: "wakeupStatusPostId_\(alarmToUpdate.id)")
                }
                
                // 変更を保存し、配列を更新する
                saveAndFetchAlarms()
                startMonitoring()
                
                // 通知を再スケジュールする
                scheduleNotification(for: alarmToUpdate)
            }
    }
    
    //アラームの状態を更新
    
    func updateAlarmStatus(id: String, isOn: Bool,isWakeup:Bool,isLeave:Bool) {
        // alarms配列から更新対象のアラーム（への参照）を探す
            if let alarmToUpdate = alarms.first(where: { $0.id == id }) {
                
                // 参照している元のオブジェクトのプロパティを直接変更する
                alarmToUpdate.isOn = isOn
                alarmToUpdate.isWakeup = isWakeup
                alarmToUpdate.isLeave = isLeave
                
                // 変更を保存し、配列を更新する
                saveAndFetchAlarms()
                startMonitoring()
                
                // 通知を再スケジュールする
                scheduleNotification(for: alarmToUpdate)
            }
    }
    
    /// アラームを削除
    func removeAlarm(id: String) {
        // 変更点 4: `alarmdata`を`alarms`に変更
        if let alarmToDelete = alarms.first(where: { $0.id == id }) {
            context.delete(alarmToDelete)
            saveAndFetchAlarms() // 変更点 5
            let notificationIDs = wakeupNotificationRequestIDs(for: alarmToDelete)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIDs)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: notificationIDs)
            startMonitoring()
        }
    }
    
    /// アラーム音を停止
    func stopAlarm(for alarm: AlarmData? = nil) {
        alarmTimer?.invalidate()
        alarmTimer = nil
        isAlarmPlaying = false
        print("🔕 アラーム音を停止しました")
        
        if let alarm {
            let notificationIDs = wakeupNotificationRequestIDs(for: alarm)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIDs)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: notificationIDs)
        }
    }
    
    /// 特定の日付のアラームを取得
    func getAlarm(for date: Date) -> AlarmData? {
        
        fetchAlarms()
        
        var calendar = Calendar.current

        if let existingAlarm = alarms.first(where: { alarm -> Bool in
            
            // 👇 デバッグ用のprint文を追加
            print("DEBUG: 比較開始 ----")
            print("  アラームの日付: \(alarm.date)")
            print("  アラームの起床: \(alarm.wakeUpTime)")
            print("  アラームの出発: \(alarm.leaveTime)")
            print("  検索する日付: \(date)")
            
            let isMatch = Calendar.current.isDate(alarm.date, inSameDayAs: date)
            print("  一致したか？ -> \(isMatch)")
            print("--------------------")
            
            return isMatch
            
        }) {
            print("✅ 一致するアラームが見つかりました: \(existingAlarm)")
            return existingAlarm
        } else {
            print("❌ 一致するアラームは見つかりませんでした。")
            return nil
        }
        
        // 変更点 4: `alarmdata`を`alarms`に変更
//        if let existingAlarm = alarms.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date)  }) {
//            return existingAlarm
//        } else {
//
//            return nil
//        }
    }
    
    /// 今日のアラームを取得
    func getTodayAlarm() -> AlarmData? {

        if let todayalarm = getAlarm(for: Date()) {
            currentAlarm = todayalarm
            return todayalarm
        }else{
            currentAlarm = nil
            return nil
        }

    }
    
    func setTodayAlarm(){
        if let todayalarm = getAlarm(for: Date()) {
            currentAlarm = todayalarm
           
        }else{
            currentAlarm = nil
         
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() { /* ... 変更なし ... */ }
    private func requestNotificationPermission() { /* ... 変更なし ... */ }
    
    // 変更点 6: メソッド名を変更し、責務を明確化
    /// 変更を保存し、データを再取得して`alarms`配列を更新する
    private func saveAndFetchAlarms() {
        do {
            try context.save()
//            fetchAlarms()
            let descriptor = FetchDescriptor<AlarmData>(sortBy: [SortDescriptor(\.date)])
            self.alarms = try context.fetch(descriptor)
        } catch {
            print("データの保存に失敗: \(error)")
        }
        fetchAlarms() // 保存後に必ずデータを再取得
    }
    
    //タイマーで時間監視を開始
    func startMonitoring() {
        stopMonitoring()
        
        // 今日のアラームを取得
        guard let todayAlarm = getTodayAlarm() else { return }
        currentAlarm = todayAlarm
        
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkAlarmTime()
        }
        
        // 即座に1回チェック
        checkAlarmTime()
    }
    
    //タイマー停止
    private func stopMonitoring() {
        let alarmToStop = currentAlarm
        timer?.invalidate()
        timer = nil
        stopAlarm(for: alarmToStop) // アラーム音も停止し通知もキャンセル
        currentAlarm = nil
    }
    
    //アラーム時間になったかをチェック
    private func checkAlarmTime() {
        guard let alarm = getTodayAlarm() else {
            if isAlarmPlaying {
                stopAlarm()
            }
            return
        }

        currentAlarm = alarm

        let now = Date()
        let shouldRingWakeupAlarm = alarm.isOn && !alarm.isWakeup && now >= alarm.wakeUpTime

        if shouldRingWakeupAlarm {
            startAlarmSound()
        } else if isAlarmPlaying {
            stopAlarm()
        }
    }
    
    // アラーム音を繰り返し再生開始
    private func startAlarmSound() {
        // 既にアラームが鳴っている場合は何もしない
        guard !isAlarmPlaying else { return }
        
        isAlarmPlaying = true
        print("🔔 アラーム音を開始します！")
        
        // 即座に1回再生
        playSystemSound()
        
        // 3秒間隔で繰り返し再生
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.playSystemSound()
        }
    }
    
    private func playSystemSound() {
#if targetEnvironment(simulator)
        print("🔔 アラーム音が鳴りました！")
#else
        AudioServicesPlaySystemSound(1005) // アラーム音
#endif
    }
    
    
    /// ローカル通知をスケジュール (30秒間音付き)
    func scheduleNotification(for alarm: AlarmData) {
        let notificationIDs = wakeupNotificationRequestIDs(for: alarm)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIDs)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: notificationIDs)

        guard alarm.isOn else {
            print("アラームがオフのため、通知はスケジュールされません。")
            return
        }
        guard !alarm.isWakeup && !alarm.isLeave else {
            print("起床後のため、通知はスケジュールされません。")
            return
        }
        if alarm.wakeUpTime == alarm.leaveTime {
            return
        }
        
        let notificationDates = wakeupNotificationDates(for: alarm)
        guard !notificationDates.isEmpty else { return }
        
        let calendar = Calendar.current

        for (index, notificationDate) in notificationDates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "アラーム"
            content.body = "起床写真を撮影してください。撮るまで通知します。"
            content.sound = .default
            content.interruptionLevel = .timeSensitive

            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationID(for: alarm, index: index),
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("通知のスケジューリングに失敗しました: \(error)")
                } else {
                    print("🔔 ローカル通知をスケジュールしました: \(request.identifier)")
                }
            }
        }
    }

    private func wakeupNotificationDates(for alarm: AlarmData) -> [Date] {
        guard let wakeupDate = combinedDate(for: alarm.wakeUpTime, onSameDayAs: alarm.date) else { return [] }
        guard let leaveDate = combinedDate(for: alarm.leaveTime, onSameDayAs: alarm.date) else { return [wakeupDate] }

        let now = Date()
        let endDate = max(wakeupDate, leaveDate)
        var nextDate = wakeupDate

        if now > wakeupDate {
            let elapsed = now.timeIntervalSince(wakeupDate)
            let completedIntervals = Int(elapsed / wakeupNotificationInterval)
            nextDate = wakeupDate.addingTimeInterval(Double(completedIntervals + 1) * wakeupNotificationInterval)
        }

        var dates: [Date] = []
        while nextDate <= endDate && dates.count < maxWakeupNotificationCount {
            dates.append(nextDate)
            nextDate = nextDate.addingTimeInterval(wakeupNotificationInterval)
        }

        if dates.isEmpty && wakeupDate > now {
            dates.append(wakeupDate)
        }

        return dates
    }

    private func combinedDate(for time: Date, onSameDayAs date: Date) -> Date? {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second ?? 0
        return calendar.date(from: dateComponents)
    }

    private func wakeupNotificationRequestIDs(for alarm: AlarmData) -> [String] {
        (0..<maxWakeupNotificationCount).map { notificationID(for: alarm, index: $0) }
    }

    private func notificationID(for alarm: AlarmData, index: Int) -> String {
        "\(alarm.id)-wakeup-\(index)"
    }
}

extension AlarmService {
    /// 出発アラームや外部から直接呼び出す用
    func startAlarm() {
        startAlarmSound()
    }
}
